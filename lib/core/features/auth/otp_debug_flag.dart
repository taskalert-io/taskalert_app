/// TEMPORARY: the backend echoes the generated OTP in the send/resend OTP
/// response so the UI can auto-fill it instead of requiring a real SMS.
/// This was previously gated to `kDebugMode` only ("a release build must
/// never read or display this"); turned on for production too, for now,
/// until real SMS delivery is wired up. Flip back to `false` (or delete
/// this file and restore the `kDebugMode` checks in `login_controller.dart`
/// / `signup_controller.dart`) once it is.
const bool showOtpInProduction = true;
