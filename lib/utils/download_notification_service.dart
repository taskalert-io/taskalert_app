import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

/// Shows a system notification when an in-app download finishes, with a
/// tap action that opens the saved file directly — used by the "download"
/// buttons on task attachments/proofs in `MyTaskDetails.dart`, since those
/// downloads happen silently in-app rather than through the OS's own
/// download manager (which normally provides this for free).
class DownloadNotificationService {
  DownloadNotificationService._();
  static final DownloadNotificationService instance =
      DownloadNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'downloads_channel';
  static const _channelName = 'Downloads';
  static const _channelDescription =
      'Notifies when a file you downloaded in-app finishes saving';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Prompts for permission as part of init, rather than needing a
    // separately-typed platform-specific plugin lookup that can drift
    // across flutter_local_notifications versions.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final path = response.payload;
        if (path != null && path.isNotEmpty) {
          OpenFile.open(path);
        }
      },
    );

    // Android 13+ requires an explicit runtime grant before any
    // notification actually shows, even with the manifest permission
    // declared.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Shows the "Download complete" notification for [filePath]. Tapping it
  /// (or tapping the in-app snackbar this pairs with) opens the file with
  /// whatever app the device has registered for its type.
  Future<void> showDownloadComplete({
    required String fileName,
    required String filePath,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // A stable-enough unique id — ms-since-epoch collides only if two
    // downloads finish in the same millisecond.
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _plugin.show(
      id,
      'Download complete',
      fileName,
      details,
      payload: filePath,
    );
  }
}
