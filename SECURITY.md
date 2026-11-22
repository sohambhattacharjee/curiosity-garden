# Security and privacy

Please report security vulnerabilities privately through the repository's Security → Report a vulnerability control when available. If it is unavailable, open a minimal issue asking the maintainer for a private channel without disclosing exploit details or private records.

Do not post children's reports, PINs, personal data, or signing credentials. The app has no accounts, analytics, ads, network content service, or synchronization. Progress is local, atomically saved with iOS file protection and excluded from device backups. The parent PIN uses a random salt and PBKDF2-HMAC-SHA256 (210,000 rounds), stored in a device-only, unlocked-device Keychain item. Five failed attempts trigger a five-minute cooldown; attempts during cooldown do not run verification. The parent gate protects normal app navigation, not a compromised or unlocked development device.

Detailed answers expire after 90 days on launch and during use; subject learning and total play time persist. A local-only app cannot remove files while it is not running, or offer tamper-proof civil time across device resets. Clock rollback or detected restart restarts the away interval conservatively; forward clock changes cannot shorten a break on the same boot. Never use uninstall/reinstall as a routine PIN recovery or session-reset mechanism.
