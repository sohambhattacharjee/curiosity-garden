import SwiftUI
import Combine
import GardenCore

@main struct CuriosityGardenApp: App {
    @StateObject private var store = GardenStore()
    var body: some Scene { WindowGroup { GardenView().environmentObject(store) } }
}
private enum Palette {
    static let cream = Color(red: 0.98, green: 0.969, blue: 0.941)
    static let sage = Color(red: 0.89, green: 0.937, blue: 0.906)
    static let green = Color(red: 0.208, green: 0.4, blue: 0.325)
    static let ink = Color(red: 0.141, green: 0.204, blue: 0.227)
}
private struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(Palette.ink)
            .background(Palette.sage, in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
private struct NextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(isEnabled ? .white : Palette.ink)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isEnabled ? Palette.green : Color(red: 0.906, green: 0.929, blue: 0.973), in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
private struct ReadingText: ViewModifier {
    @EnvironmentObject var store: GardenStore
    @ScaledMetric(relativeTo: .body) private var scale = 1.0
    let role: ReadingRole
    var factor: Double = 1
    func body(content: Content) -> some View {
        content.font(.system(size: store.state.reading.points(for: role) * min(scale, 1.12) * factor,
                             weight: role == .question ? .semibold : .regular,
                             design: store.state.reading.font == .rounded ? .rounded : .default))
            .lineSpacing(4 * min(scale, 1.12))
    }
}
private extension View {
    func readingText(_ role: ReadingRole = .body, factor: Double = 1) -> some View { modifier(ReadingText(role: role, factor: factor)) }
}
struct GardenView: View {
    @EnvironmentObject var store: GardenStore
    @Environment(\.scenePhase) private var phase
    private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationStack {
            Group {
                if store.error == nil, !store.blocked, !store.recap, let question = store.state.round?.pending {
                    GeometryReader { geometry in
                        ViewThatFits(in: .vertical) {
                            questionScreen(question, factor: 1, wide: geometry.size.width > geometry.size.height)
                            questionScreen(question, factor: 0.9, wide: geometry.size.width > geometry.size.height)
                            questionScreen(question, factor: 0.8, wide: geometry.size.width > geometry.size.height)
                            ScrollView {
                                questionScreen(question, factor: 0.8, wide: geometry.size.width > geometry.size.height)
                            }
                        }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    }.navigationTitle("Curiosity Garden").navigationBarTitleDisplayMode(.inline)
                } else { standardContent }
            }.background(Palette.cream).foregroundStyle(Palette.ink)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Parents", systemImage: "lock") { store.parentOpen = true; store.tick() } } }
                .sheet(isPresented: $store.parentOpen, onDismiss: { store.closeParent() }) { ParentView() }
        }.tint(Palette.green).preferredColorScheme(.light)
            .onReceive(pulse) { _ in store.tick() }
            .onChange(of: phase) { _, value in store.lifecycle(value) }
            .privacySensitive()
            .overlay { if !store.active { Palette.cream.ignoresSafeArea().overlay { Label("Curiosity Garden", systemImage: "leaf").font(.title).foregroundStyle(Palette.ink) } } }
    }
    private var standardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Curiosity Garden", systemImage: "leaf").readingText(.question).accessibilityAddTraits(.isHeader)
                if store.allowsDrafts { Text("Draft questions · Not reviewed").font(.callout).padding().background(Palette.sage, in: RoundedRectangle(cornerRadius: 12)) }
                if let error = store.error { Text(error) }
                else if store.state.grade == nil { SetupView() }
                else if store.blocked {
                    Text("Time to rest and explore").readingText(.question)
                    Text("Your garden will be ready after a 30-minute break. You can put the device away now.")
                    Text("About \(Int(ceil(store.state.clock.remainingBreak(now: Date(), grade: store.state.grade ?? 0) / 60))) minutes remaining.")
                } else if store.recap { recap }
                else {
                    Text("A little wonder, one question at a time.").readingText(.question)
                    Text("Explore school subjects and the world around you. Take your time.")
                    Button("Explore the garden") { store.start() }.buttonStyle(.borderedProminent).foregroundStyle(.white)
                }
            }.readingText().frame(maxWidth: 680, alignment: .leading).padding(20).frame(maxWidth: .infinity)
        }
    }
    private var draftBadge: some View {
        Text("Draft questions · Not reviewed").font(.system(size: 13)).padding(.horizontal, 12).padding(.vertical, 6)
            .background(Palette.sage, in: RoundedRectangle(cornerRadius: 8))
    }
    private func questionScreen(_ question: Question, factor: Double, wide: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !wide && store.allowsDrafts { draftBadge }
            if wide {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10 * factor) {
                        if store.allowsDrafts { draftBadge }
                        questionHeading(question, factor: factor)
                        questionFeedback(question, factor: factor)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 10 * factor) {
                        answerChoices(question, factor: factor, columns: 2)
                        questionControls
                    }.frame(maxWidth: .infinity)
                }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
            } else { questionView(question, factor: factor) }
        }.frame(maxWidth: wide ? 1000 : 680).padding(.horizontal, 12).padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.large)
    }
    private func questionView(_ question: Question, factor: Double) -> some View {
        VStack(alignment: .leading, spacing: 10 * factor) {
            questionHeading(question, factor: factor)
            answerChoices(question, factor: factor, columns: 1)
            questionFeedback(question, factor: factor)
            questionControls
        }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
    private func questionHeading(_ question: Question, factor: Double) -> some View {
        VStack(alignment: .leading, spacing: 10 * factor) {
            Text(question.subject.title).readingText(.note, factor: factor)
            Text(question.prompt).readingText(.question, factor: factor).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
            if question.subject == .math && question.level == 0 {
                let numbers = question.prompt.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
                HStack(spacing: 16) {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { _, number in
                        HStack(spacing: 4) { ForEach(0..<min(number, 8), id: \.self) { _ in Image(systemName: "circle.fill").font(.caption) } }
                            .accessibilityElement(children: .ignore).accessibilityLabel("\(number) counting dots")
                    }
                }.foregroundStyle(Palette.green)
            }
        }
    }
    private func answerChoices(_ question: Question, factor: Double, columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(question.choices.indices, id: \.self) { index in
                Button { store.answer(.choice(index)) } label: {
                    HStack {
                        Text(question.choices[index]).readingText(.answer, factor: factor).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        if store.state.round?.response != nil && index == question.correct {
                            Image(systemName: "checkmark.circle.fill").accessibilityLabel("Correct answer")
                        }
                    }.padding(.horizontal, 12).padding(.vertical, 6).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.buttonStyle(AnswerButtonStyle()).disabled(store.state.round?.response != nil)
            }
        }
    }
    @ViewBuilder private func questionFeedback(_ question: Question, factor: Double) -> some View {
        if let response = store.state.round?.response {
            Text(response == .choice(question.correct) ? "Yes, that's it." : "Let's learn together.").readingText(.answer, factor: factor)
            Text("The answer is \(question.choices[question.correct]). \(question.explanation)").readingText(.body, factor: factor).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var questionControls: some View {
        HStack(spacing: 12) {
            Button { store.answer(.unsure) } label: {
                Text("I'm not sure").frame(maxWidth: .infinity, minHeight: 44)
            }
                .buttonStyle(AnswerButtonStyle()).disabled(store.state.round?.response != nil)
            Button { store.next() } label: {
                Text("Next").frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(NextButtonStyle()).disabled(store.state.round?.response == nil)
        }.font(.system(size: 18, design: store.state.reading.font == .rounded ? .rounded : .default))
    }
    private var recap: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What we discovered").readingText(.question)
            ForEach(Array((store.state.round?.answers ?? []).suffix(2))) { record in Text(record.question.explanation) }
            Text("Thank you for exploring. There's a whole world to notice away from the screen.")
            if store.state.round?.endReason == .contentUnavailable { Text("This build needs more reviewed questions to complete the round.").readingText(.note) }
            Button("Done") { store.state.round = nil; store.recap = false; store.tick() }.buttonStyle(.borderedProminent).foregroundStyle(.white)
        }
    }
}
struct SetupView: View {
    @EnvironmentObject var store: GardenStore
    @State private var grade = 0
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A parent plants the first seed").readingText(.question)
            Text("Choose a starting grade and a private six-digit parent PIN. Progress stays on this device.")
            Picker("Starting grade", selection: $grade) { ForEach(0...5, id: \.self) { Text($0 == 0 ? "Kindergarten" : "Grade \($0)").tag($0) } }
            if ParentPIN.exists { Text("Enter the existing device parent PIN.") }
            SecureField("Six-digit parent PIN", text: $pin).keyboardType(.numberPad).textContentType(.newPassword)
            if !ParentPIN.exists { SecureField("Confirm PIN", text: $confirmation).keyboardType(.numberPad) }
            Text("Keep your PIN private. If you forget it, use device authentication in Parents to set a new one.").readingText(.note)
            Button("Save and begin") {
                let okay = ParentPIN.exists ? ParentPIN.verify(pin) : (pin == confirmation && ParentPIN.create(pin))
                if okay { store.setup(grade: grade); pin = ""; confirmation = "" }
                else { message = "Use matching six-digit PINs, or check the existing PIN. After five failed attempts, wait five minutes." }
            }.buttonStyle(.borderedProminent).foregroundStyle(.white)
            Text(message)
        }.textFieldStyle(.roundedBorder)
    }
}
struct ParentView: View {
    @EnvironmentObject var store: GardenStore
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var message = ""
    @State private var showHistory = false
    @State private var window = ReportWindow.ninetyDays
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var pinMessage = ""
    @State private var forgotPIN = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.parentUnlocked { report } else if forgotPIN { recovery } else { gate }
                }.padding(24).frame(maxWidth: 700).font(.title3)
            }.navigationTitle("Parents").toolbar {
                Button("Lock and close") { store.closeParent(); dismiss() }
            }
        }
    }
    private var gate: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Parent access").font(.title)
            SecureField("Parent PIN", text: $pin).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            Button("Unlock") {
                store.parentUnlocked = ParentPIN.verify(pin)
                pin = ""
                message = store.parentUnlocked ? "" : "PIN not accepted. After five failed attempts, wait five minutes."
            }
            if ParentPIN.exists {
                Button("Forgot PIN?") { pin = ""; message = ""; forgotPIN = true }
            }
            Text(message)
        }
    }
    private var recovery: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Reset parent PIN").font(.title)
            Text("Use Face ID, Touch ID, or this device's passcode. Anyone able to unlock this device can reset the parent PIN.")
            Text("Learning progress, session limits, and breaks are preserved.").font(.footnote)
            SecureField("New six-digit PIN", text: $newPIN).keyboardType(.numberPad).textContentType(.newPassword)
            SecureField("Confirm new PIN", text: $confirmPIN).keyboardType(.numberPad).textContentType(.newPassword)
            Button(store.recoveringPIN ? "Authenticating…" : "Verify device and reset PIN") {
                Task {
                    let result = await store.recoverParentPIN(replacement: newPIN, confirmation: confirmPIN)
                    newPIN = ""; confirmPIN = ""; message = result.message
                    if result == .success { forgotPIN = false }
                }
            }.buttonStyle(.borderedProminent).disabled(store.recoveringPIN)
            Button("Back to PIN entry") { newPIN = ""; confirmPIN = ""; message = ""; forgotPIN = false }
            Text(message)
        }.textFieldStyle(.roundedBorder).disabled(store.recoveringPIN)
    }
    private var report: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Learning overview").font(.title.bold())
            Picker("Report period", selection: $window) {
                ForEach(ReportWindow.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Text("Includes today. 'I'm not sure' counts as an attempted, non-correct answer. Unanswered questions are excluded.")
            Text("Play in this period: \(SubjectReport.playTimeText(store.reportSeconds(window)))")
            Text("Time by day is recorded from this update onward.").font(.footnote)
            Text("Total foreground play: \(SubjectReport.playTimeText(store.state.clock.totalPlay))")
            ForEach(GardenCore.Subject.allCases, id: \.self) { subject in subjectSummary(subject) }
            gradeSetting
            readingSettings
            pinSettings
            contentStatus
            Toggle("Question-by-question history", isOn: $showHistory)
            if showHistory {
                ForEach(store.reportHistory(window).reversed()) { record in historyRow(record) }
            }
        }
    }
    private var readingSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading comfort").font(.title2.bold())
            Picker("Child reading font", selection: Binding(get: { store.state.reading.font }, set: {
                var preferences = store.state.reading; preferences.font = $0; store.updateReading(preferences)
            })) {
                ForEach(ReadingFont.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Picker("Child text size", selection: Binding(get: { store.state.reading.size }, set: {
                var preferences = store.state.reading; preferences.size = $0; store.updateReading(preferences)
            })) {
                ForEach(ReadingSize.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Text("a b d p q · 1 2 3").readingText(.answer)
            Text("Both fonts work offline. Reading text has a capped size so questions and controls fit on one screen. Choose the one your child finds comfortable.").font(.footnote)
        }
    }
    private var pinSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change parent PIN").font(.title2.bold())
            SecureField("Current PIN", text: $currentPIN).keyboardType(.numberPad)
            SecureField("New six-digit PIN", text: $newPIN).keyboardType(.numberPad)
            SecureField("Confirm new PIN", text: $confirmPIN).keyboardType(.numberPad)
            Button("Save new PIN and lock") {
                let changed = ParentPIN.change(current: currentPIN, replacement: newPIN, confirmation: confirmPIN)
                currentPIN = ""; newPIN = ""; confirmPIN = ""
                if changed { store.parentUnlocked = false; dismiss() }
                else { pinMessage = "PIN not changed. Check the current PIN and matching six-digit replacement. After five wrong attempts, wait five minutes." }
            }
            Text(pinMessage)
        }.textFieldStyle(.roundedBorder)
    }
    private var contentStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question content").font(.title2.bold())
            Text("\(store.bank.filter { $0.status == .reviewed && $0.valid }.count) reviewed · \(store.bank.filter { $0.status == .draft }.count) draft placeholders")
            Text("Drafts are for development. The question bank is reviewed separately before a family-ready Release.").font(.footnote)
        }
    }
    private var gradeSetting: some View {
        VStack(alignment: .leading) {
            Picker("Selected grade (reading and future session limits)", selection: Binding(get: { store.state.grade ?? 0 }, set: { store.setup(grade: $0) })) {
                ForEach(0...5, id: \.self) { Text(SubjectReport.gradeName($0)).tag($0) }
            }
            Text("Changing grade preserves subject learning and the current session allowance.").font(.footnote)
        }
    }
    private func subjectSummary(_ subject: GardenCore.Subject) -> some View {
        let report = SubjectReport(subject: subject, level: store.state.progress[subject]?.level ?? 0, history: store.reportHistory(window))
        return VStack(alignment: .leading) {
            Text(subject.title).font(.headline)
            Text(report.accuracyText)
            Text(report.difficultyText)
            if !report.practiceFacts.isEmpty {
                Text("Practice together:")
                ForEach(report.practiceFacts, id: \.self) { Text($0) }
            }
        }
    }
    private func historyRow(_ record: AnswerRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.question.prompt).font(.headline)
            Text("Answer: \(SubjectReport.answerText(record)) · Correct: \(record.question.choices[record.question.correct])")
            Text(record.date.formatted()).font(.caption)
            Text("Content: \(record.question.status.rawValue)").font(.caption)
        }.padding(.vertical, 8)
    }
}
