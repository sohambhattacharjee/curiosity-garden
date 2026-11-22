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
struct GardenView: View {
    @EnvironmentObject var store: GardenStore
    @Environment(\.scenePhase) private var phase
    private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Label("Curiosity Garden", systemImage: "leaf").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                    if store.allowsDrafts { Text("Family development build · Draft questions, not reviewed").font(.callout).padding().background(Palette.sage, in: RoundedRectangle(cornerRadius: 12)) }
                    if let error = store.error { Text(error) }
                    else if store.state.grade == nil { SetupView() }
                    else if store.blocked {
                        Image(systemName: "sun.horizon").font(.largeTitle)
                        Text("Time to rest and explore").font(.title2.bold())
                        Text("Your garden will be ready after a 30-minute break. You can put the device away now.")
                        Text("About \(Int(ceil(store.state.clock.remainingBreak(now: Date(), grade: store.state.grade ?? 0) / 60))) minutes remaining.")
                    } else if store.recap { recap }
                    else if let question = store.state.round?.pending { questionView(question) }
                    else {
                        Text("A little wonder, one question at a time.").font(.title2)
                        Text("Explore school subjects and the world around you. Take your time.")
                        Button("Explore the garden") { store.start() }.buttonStyle(.borderedProminent).foregroundStyle(.white)
                    }
                }.frame(maxWidth: 680, alignment: .leading).padding(24).frame(maxWidth: .infinity)
            }.background(Palette.cream).foregroundStyle(Palette.ink)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Parents", systemImage: "lock") { store.parentOpen = true; store.tick() } } }
                .sheet(isPresented: $store.parentOpen, onDismiss: { store.parentUnlocked = false; store.tick() }) { ParentView() }
        }.tint(Palette.green).preferredColorScheme(.light)
            .onReceive(pulse) { _ in store.tick() }
            .onChange(of: phase) { _, value in store.lifecycle(value) }
            .privacySensitive()
            .overlay { if !store.active { Palette.cream.ignoresSafeArea().overlay { Label("Curiosity Garden", systemImage: "leaf").font(.title).foregroundStyle(Palette.ink) } } }
    }
    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.subject.title).font(.subheadline)
            Text(question.prompt).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            if question.subject == .math && question.level == 0 {
                let numbers = question.prompt.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
                HStack(spacing: 16) {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { _, number in
                        HStack(spacing: 4) { ForEach(0..<min(number, 8), id: \.self) { _ in Image(systemName: "circle.fill").font(.caption) } }
                            .accessibilityElement(children: .ignore).accessibilityLabel("\(number) counting dots")
                    }
                }.foregroundStyle(Palette.green)
            }
            ForEach(question.choices.indices, id: \.self) { index in
                Button { store.answer(.choice(index)) } label: {
                    HStack { Text(question.choices[index]); Spacer(); if store.state.round?.response != nil && index == question.correct { Label("Correct answer", systemImage: "checkmark.circle") } }.frame(maxWidth: .infinity, minHeight: 44).padding(12)
                }.background(Palette.sage, in: RoundedRectangle(cornerRadius: 14)).disabled(store.state.round?.response != nil)
            }
            if let response = store.state.round?.response {
                Text(response == .choice(question.correct) ? "Yes, that's it." : "Let's learn together.").font(.headline)
                Text("The answer is \(question.choices[question.correct]). \(question.explanation)")
                Button("Next") { store.next() }.buttonStyle(.borderedProminent).foregroundStyle(.white)
            } else { Button("I'm not sure") { store.answer(.unsure) }.frame(minHeight: 44) }
        }.padding(24).background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
    private var recap: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What we discovered").font(.title2.bold())
            ForEach(Array((store.state.round?.answers ?? []).suffix(2))) { record in Text(record.question.explanation) }
            Text("Thank you for exploring. There's a whole world to notice away from the screen.")
            if store.state.round?.pending == nil && (store.state.round?.answers.count ?? 0) < 10 { Text("This build needs more reviewed questions to complete the round.").font(.callout) }
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
            Text("A parent plants the first seed").font(.title2.bold())
            Text("Choose a starting grade and a private six-digit parent PIN. Progress stays on this device.")
            Picker("Starting grade", selection: $grade) { ForEach(0...5, id: \.self) { Text($0 == 0 ? "Kindergarten" : "Grade \($0)").tag($0) } }
            if ParentPIN.exists { Text("Enter the existing device parent PIN.") }
            SecureField("Six-digit parent PIN", text: $pin).keyboardType(.numberPad).textContentType(.newPassword)
            if !ParentPIN.exists { SecureField("Confirm PIN", text: $confirmation).keyboardType(.numberPad) }
            Text("Keep your PIN safe. There is no bypass or online recovery. See the family-build guide for device-data reset instructions.").font(.footnote)
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.parentUnlocked { report } else { gate }
                }.padding(24).frame(maxWidth: 700)
            }.navigationTitle("Parents").toolbar {
                Button("Lock and close") { store.parentUnlocked = false; dismiss() }
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
            Text(message)
        }
    }
    private var report: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Learning overview").font(.title.bold())
            Text("Last 90 days · 'I'm not sure' counts as an attempted, non-correct answer. Unanswered questions are excluded. Interrupted rounds keep answered questions.")
            Text("Total foreground play: \(Int(store.state.clock.totalPlay / 60)) minutes")
            ForEach(GardenCore.Subject.allCases, id: \.self) { subject in subjectSummary(subject) }
            gradeSetting
            Toggle("Question-by-question history", isOn: $showHistory)
            if showHistory {
                ForEach(store.state.history.reversed()) { record in historyRow(record) }
            }
        }
    }
    private var gradeSetting: some View {
        VStack(alignment: .leading) {
            Picker("Selected grade (reading and future session limits)", selection: Binding(get: { store.state.grade ?? 0 }, set: { store.setup(grade: $0) })) {
                ForEach(0...5, id: \.self) { Text(level($0)).tag($0) }
            }
            Text("Changing grade preserves subject learning and the current session allowance.").font(.footnote)
        }
    }
    private func subjectSummary(_ subject: GardenCore.Subject) -> some View {
        let records = store.state.history.filter { $0.question.subject == subject }
        let correct = records.filter { $0.correct }.count
        let percent = records.isEmpty ? 0 : Int(Double(correct) / Double(records.count) * 100)
        let accuracy = records.isEmpty ? "No answers yet" : "\(correct) correct of \(records.count) attempts (\(percent)%)"
        return VStack(alignment: .leading) {
            Text(subject.title).font(.headline)
            Text(accuracy)
            Text("Difficulty: \(level(store.state.progress[subject]?.level ?? 0)) · \(trend(records))")
            if records.suffix(5).contains(where: { !$0.correct }) {
                Text("Practice: revisit recent explanations together.")
            }
        }
    }
    private func historyRow(_ record: AnswerRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.question.prompt).font(.headline)
            Text("Answer: \(answer(record)) · Correct: \(record.question.choices[record.question.correct])")
            Text(record.date.formatted()).font(.caption)
            Text("Content: \(record.question.status.rawValue)").font(.caption)
        }.padding(.vertical, 8)
    }
    private func level(_ value: Int) -> String { value == 0 ? "K" : "Grade \(value)" }
    private func trend(_ records: [AnswerRecord]) -> String {
        guard let first = records.first, let last = records.last else { return "No trend yet" }
        return last.levelAfter > first.levelAfter ? "Moving to harder material" : last.levelAfter < first.levelAfter ? "Practicing foundations" : "Steady"
    }
    private func answer(_ record: AnswerRecord) -> String {
        if case let .choice(index) = record.response { return record.question.choices[index] }
        return "I'm not sure"
    }
}
