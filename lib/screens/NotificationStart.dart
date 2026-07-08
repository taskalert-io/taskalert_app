import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import 'NotificationScreen.dart';

// ─────────────────────────────────────────────────────────────────────────
// NotificationStart
//
// API-ready notification feed screen.
//
// WHAT CHANGED vs. the previous revision:
//  • Added `isDefaultActive` to `NotifCardData` — a server-driven flag that
//    decides which card opens selected/active when the screen first loads.
//    This replaces the old behavior of just picking whichever card happened
//    to be first in the list, which is fragile once real API data (with
//    its own ordering / pagination) is involved. The user can still tap
//    any other card to change the active one — `isDefaultActive` only
//    decides the *initial* state, exactly once, on first load.
//  • `status` (unread/read) and `isDefaultActive` (selected on open) are
//    fully independent fields. A card can be the default-active card and
//    still be `read` (so it disappears when "Only show unread" is on),
//    or be `unread` and not be the default-active card. Selecting a card
//    in the UI does NOT change its `status` — see the note at the bottom
//    of this file if you want tapping a card to also mark it read.
//  • Seed data: `ntf_1` is `status: NotifStatus.read` and
//    `isDefaultActive: true` (opens active by default, but is filtered out
//    when "Only show unread" is on). `ntf_2` and `ntf_3` are `unread` and
//    not default-active (plain cards on open, but visible when the unread
//    filter is on).
//  • Added `NotificationSettingsPopup` — the "⋮" icon in the title row now
//    opens a settings dialog (Never / Periodically / Instantly frequency,
//    a desktop-notifications toggle, and an "All notification settings"
//    row) instead of doing nothing. See `_titleRow` for the wiring.
//
// EXPECTED API CONTRACT (adjust `ApiNotificationRepository` to match your
// actual backend — this is the shape the fromJson() factories below assume):
//
// GET {baseUrl}/users/{userId}/notifications?page=1&pageSize=20
// {
//   "data": [
//     {
//       "id": "ntf_123",
//       "title": "Test new messaging for SMB market",
//       "date": "2026-08-10T00:00:00Z",
//       "status": "unread" | "read" | "none",
//       "highlighted": false,
//       "isDefaultActive": true,
//       "badge": { "bold": "Company Overview: ", "normal": "Priorities" },
//       "subBadge": { "bold": null, "normal": null },
//       "requiresAction": false,
//       "lines": [
//         {
//           "person": {
//             "initials": "BC",
//             "avatarUrl": "https://.../avatar.jpg",
//             "avatarColor": "#7C6FE8"
//           },
//           "boldName": "Brian Cervino",
//           "actionText": null,
//           "leadingIcon": "clock",
//           "subActionText": "Added a due date of Aug 10 at 6:00 PM",
//           "subIcon": "clock",
//           "timestamp": "2026-08-09T22:08:00Z"
//         }
//       ],
//       "linkPreview": { "label": "Marketing designs", "url": "https://..." },
//       "hasPromo": false
//     }
//   ],
//   "meta": { "page": 1, "pageSize": 20, "hasMore": true }
// }
//
// On error, the server may optionally send a body like:
//   { "message": "..." }              or
//   { "error": { "message": "..." } }
// `_ApiClient` will surface that message instead of a generic one.
//
// POST {baseUrl}/users/{userId}/notifications/read-all
// POST {baseUrl}/users/{userId}/notifications/unread-all
// POST {baseUrl}/users/{userId}/notifications/{id}/read
// POST {baseUrl}/users/{userId}/notifications/{id}/approve
// POST {baseUrl}/users/{userId}/notifications/{id}/deny
//
// pubspec.yaml additions needed:
//   http: ^1.2.0
//   cached_network_image: ^3.3.1
// ─────────────────────────────────────────────────────────────────────────

// ── Models ───────────────────────────────────────────────────────────────

enum NotifStatus { unread, read, none }

NotifStatus _statusFromApi(String? raw) {
  switch (raw) {
    case 'unread':
      return NotifStatus.unread;
    case 'read':
      return NotifStatus.read;
    default:
      return NotifStatus.none;
  }
}

Color _colorFromHex(String? hex, {Color fallback = const Color(0xFF6C5CE7)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.tryParse(value, radix: 16) ?? fallback.value);
}

/// Maps a stable string key from the API to a Flutter icon, so the backend
/// never has to know about Flutter's IconData constants.
IconData? _iconFromKey(String? key) {
  switch (key) {
    case 'clock':
      return Icons.access_time;
    case 'person_add':
      return Icons.person_add_alt;
    case 'link':
      return Icons.link;
    default:
      return null;
  }
}

class NotifPerson {
  final String? avatarUrl; // from API; null/empty -> initials fallback
  final String initials;
  final Color avatarColor;

  const NotifPerson({
    this.avatarUrl,
    required this.initials,
    this.avatarColor = const Color(0xFF6C5CE7),
  });

  factory NotifPerson.fromJson(Map<String, dynamic> json) {
    return NotifPerson(
      avatarUrl: json['avatarUrl'] as String?,
      initials: (json['initials'] as String?) ?? '?',
      avatarColor: _colorFromHex(json['avatarColor'] as String?),
    );
  }
}

class NotifActivityLine {
  final NotifPerson person;
  final String boldName;
  final String? actionText;
  final IconData? leadingIcon;
  final String? subActionText;
  final IconData? subIcon;

  final DateTime timestamp; // time for boldName/actionText line
  final DateTime? subTimestamp; // time for subActionText line
  final String? metaLabel;

  const NotifActivityLine({
    required this.person,
    required this.boldName,
    this.actionText,
    this.leadingIcon,
    this.subActionText,
    this.subIcon,
    required this.timestamp,
    this.subTimestamp,
    this.metaLabel,
  });

  factory NotifActivityLine.fromJson(Map<String, dynamic> json) {
    return NotifActivityLine(
      person: NotifPerson.fromJson(
        (json['person'] as Map<String, dynamic>?) ?? const {},
      ),
      boldName: (json['boldName'] as String?) ?? '',
      actionText: json['actionText'] as String?,
      leadingIcon: _iconFromKey(json['leadingIcon'] as String?),
      subActionText: json['subActionText'] as String?,
      subIcon: _iconFromKey(json['subIcon'] as String?),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      subTimestamp: json['subTimestamp'] != null
          ? DateTime.tryParse(json['subTimestamp'] as String)?.toLocal()
          : null,
      metaLabel: json['metaLabel'] as String?,
    );
  }
}

class LinkPreviewData {
  final String label;
  final String url;

  const LinkPreviewData({required this.label, required this.url});

  factory LinkPreviewData.fromJson(Map<String, dynamic> json) {
    return LinkPreviewData(
      label: (json['label'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
    );
  }
}

class NotifCardData {
  final String id;
  final String title;
  final DateTime date;
  final NotifStatus status;
  final String badgeBold;
  final String badgeNormal;
  final bool highlighted;
  final String? subBadgeBold;
  final String? subBadgeNormal;
  final List<NotifActivityLine> lines;
  final bool hasPromo;
  final LinkPreviewData? linkPreview;

  /// When true, the card renders an Approve / Deny action row (e.g. for
  /// access requests). Cleared automatically once approved.
  final bool requiresAction;

  /// Server-driven flag: true means this card should be selected/active
  /// when the screen first loads. Independent of `status` — a card can be
  /// `read` and still be the default-active card, or `unread` and not be.
  /// The user can still tap any other card afterward to change selection;
  /// this only decides the initial state on load.
  final bool isDefaultActive;

  const NotifCardData({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.badgeBold,
    required this.badgeNormal,
    this.highlighted = false,
    this.subBadgeBold,
    this.subBadgeNormal,
    required this.lines,
    this.hasPromo = false,
    this.linkPreview,
    this.requiresAction = false,
    this.isDefaultActive = false,
  });

  factory NotifCardData.fromJson(Map<String, dynamic> json) {
    final badge = (json['badge'] as Map<String, dynamic>?) ?? const {};
    final subBadge = (json['subBadge'] as Map<String, dynamic>?) ?? const {};
    final linkPreviewJson = json['linkPreview'] as Map<String, dynamic>?;
    return NotifCardData(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      title: (json['title'] as String?) ?? '',
      date:
          DateTime.tryParse(json['date'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      status: _statusFromApi(json['status'] as String?),
      badgeBold: (badge['bold'] as String?) ?? '',
      badgeNormal: (badge['normal'] as String?) ?? '',
      highlighted: (json['highlighted'] as bool?) ?? false,
      subBadgeBold: subBadge['bold'] as String?,
      subBadgeNormal: subBadge['normal'] as String?,
      lines: ((json['lines'] as List<dynamic>?) ?? const [])
          .map((e) => NotifActivityLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasPromo: (json['hasPromo'] as bool?) ?? false,
      linkPreview: linkPreviewJson != null
          ? LinkPreviewData.fromJson(linkPreviewJson)
          : null,
      requiresAction: (json['requiresAction'] as bool?) ?? false,
      isDefaultActive: (json['isDefaultActive'] as bool?) ?? false,
    );
  }

  NotifCardData copyWith({NotifStatus? status, bool? requiresAction}) {
    return NotifCardData(
      id: id,
      title: title,
      date: date,
      status: status ?? this.status,
      badgeBold: badgeBold,
      badgeNormal: badgeNormal,
      highlighted: highlighted,
      subBadgeBold: subBadgeBold,
      subBadgeNormal: subBadgeNormal,
      lines: lines,
      hasPromo: hasPromo,
      linkPreview: linkPreview,
      requiresAction: requiresAction ?? this.requiresAction,
      isDefaultActive: isDefaultActive,
    );
  }
}

/// Formats DateTimes the same way the reference design does
/// ("yesterday at 7:57 PM", "20 hours ago", "Aug 10"), computed live instead
/// of hardcoded, so it's correct no matter when the screen is opened.
class RelativeTime {
  static String format(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    // Purely elapsed-time based — a timestamp 20 hours old always reads
    // "20 hours ago", regardless of whether that span happens to cross
    // midnight. A calendar-day check here was silently swapping this to
    // "yesterday at 7:57 PM" for anyone testing in the evening/morning.
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) {
      return 'yesterday at ${_formatClock(dt)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return shortDate(dt);
  }

  static String shortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  static String _formatClock(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Repository abstraction ─────────────────────────────────────────────
//
// The screen only ever talks to a `NotificationRepository`. Today that's
// `MockNotificationRepository` (in-memory, no network, no URL needed).
// When a real backend exists, drop in `ApiNotificationRepository` — the
// screen doesn't change at all, since both implement the same interface.

// ── Typed API errors ────────────────────────────────────────────────────
//
// A plain `NotificationApiException(String)` is fine for a mock, but it's
// the wrong shape once a real backend is involved: callers routinely need
// to branch on *what* went wrong (log the user out on 401, show a
// "not found, it may have already been handled" toast on 404, offer a
// retry on 5xx/timeout) rather than pattern-match a message string. These
// map 1:1 onto the status codes any REST backend will actually return.

class NotificationApiException implements Exception {
  final String message;
  final int? statusCode;
  NotificationApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class NetworkUnavailableException extends NotificationApiException {
  NetworkUnavailableException()
    : super('Could not reach the server. Check your connection and try again.');
}

class RequestTimeoutException extends NotificationApiException {
  RequestTimeoutException() : super('The request timed out. Please try again.');
}

class UnauthorizedException extends NotificationApiException {
  UnauthorizedException([String? message])
    : super(
        message ?? 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
}

class ForbiddenException extends NotificationApiException {
  ForbiddenException([String? message])
    : super(
        message ?? "You don't have permission to do that.",
        statusCode: 403,
      );
}

class NotFoundException extends NotificationApiException {
  NotFoundException([String? message])
    : super(message ?? 'That notification no longer exists.', statusCode: 404);
}

class ServerException extends NotificationApiException {
  ServerException(int statusCode, [String? message])
    : super(
        message ?? 'Something went wrong on our end. Please try again.',
        statusCode: statusCode,
      );
}

class NotificationPage {
  final List<NotifCardData> items;
  final bool hasMore;
  const NotificationPage({required this.items, required this.hasMore});
}

abstract class NotificationRepository {
  Future<NotificationPage> fetchNotifications({
    required String userId,
    int page,
    int pageSize,
    bool onlyUnread,
  });

  Future<void> markAllAsRead({required String userId});

  /// Reverses [markAllAsRead] — needed so the "Mark all as read" master
  /// control can be a real toggle (checked -> unchecked marks everything
  /// unread again) instead of a one-way action.
  Future<void> markAllAsUnread({required String userId});

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  /// Approve an action-required notification (e.g. an edit-access
  /// request). Implementations should mark it read server-side too.
  Future<void> approve({
    required String userId,
    required String notificationId,
  });

  /// Deny an action-required notification.
  Future<void> deny({required String userId, required String notificationId});

  void dispose() {}
}

/// Thin HTTP layer that every endpoint in [ApiNotificationRepository] goes
/// through, so auth headers, timeouts, retries, and error-mapping live in
/// exactly one place instead of being copy-pasted per method — which is
/// the usual place integrations rot once a real backend's edge cases show
/// up (expired tokens, flaky connections, 500s with a body worth reading).
class _ApiClient {
  _ApiClient({
    required this.baseUrl,
    required http.Client client,
    this.getAuthToken,
    this.timeout = const Duration(seconds: 15),
    this.maxGetRetries = 1,
  }) : _client = client;

  final String baseUrl;
  final http.Client _client;

  /// Called fresh before every request, so a token refreshed elsewhere in
  /// the app is always picked up without this repository knowing anything
  /// about how auth works.
  final Future<String?> Function()? getAuthToken;

  final Duration timeout;

  /// Only idempotent GETs are retried; POSTs (approve/deny/mark-read) are
  /// not, so a flaky connection can't cause a mutation to fire twice.
  final int maxGetRetries;

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = await getAuthToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>?> get(Uri uri) =>
      _send((headers) => _client.get(uri, headers: headers), retryable: true);

  Future<Map<String, dynamic>?> post(Uri uri) =>
      _send((headers) => _client.post(uri, headers: headers));

  Future<Map<String, dynamic>?> _send(
    Future<http.Response> Function(Map<String, String> headers) call, {
    bool retryable = false,
  }) async {
    final headers = await _headers();
    var attempt = 0;
    final maxAttempts = retryable ? maxGetRetries + 1 : 1;

    while (true) {
      attempt++;
      try {
        final response = await call(headers).timeout(timeout);
        return _decode(response);
      } on TimeoutException {
        if (attempt < maxAttempts) continue;
        throw RequestTimeoutException();
      } on NotificationApiException {
        rethrow;
      } catch (_) {
        if (attempt < maxAttempts) continue;
        throw NetworkUnavailableException();
      }
    }
  }

  Map<String, dynamic>? _decode(http.Response response) {
    final code = response.statusCode;
    if (code == 401) throw UnauthorizedException(_serverMessage(response));
    if (code == 403) throw ForbiddenException(_serverMessage(response));
    if (code == 404) throw NotFoundException(_serverMessage(response));
    if (code >= 500) throw ServerException(code, _serverMessage(response));
    if (code >= 400) {
      throw NotificationApiException(
        _serverMessage(response) ?? 'Request failed ($code).',
        statusCode: code,
      );
    }
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// Servers commonly send `{ "message": "..." }` or
  /// `{ "error": { "message": "..." } }` on failure — surface that instead
  /// of a generic string whenever it's present.
  String? _serverMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          final errorMessage = error['message'];
          if (errorMessage is String && errorMessage.isNotEmpty) {
            return errorMessage;
          }
        }
      }
    } catch (_) {
      // Non-JSON or empty error body — fall back to the generic message.
    }
    return null;
  }

  void dispose() => _client.close();
}

/// Real backend implementation — wire this up once an API exists.
/// Nothing else in the screen needs to change: just construct
/// `NotificationStart(repository: ApiNotificationRepository(baseUrl: ...))`.
///
/// [getAuthToken] is optional and called before every request; wire it to
/// your existing auth/session layer (e.g. `() => authStore.currentToken`)
/// so token refreshes are picked up automatically without touching this
/// class again.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({
    required String baseUrl,
    http.Client? client,
    Future<String?> Function()? getAuthToken,
  }) : _api = _ApiClient(
         baseUrl: baseUrl,
         client: client ?? http.Client(),
         getAuthToken: getAuthToken,
       );

  final _ApiClient _api;

  @override
  Future<NotificationPage> fetchNotifications({
    required String userId,
    int page = 1,
    int pageSize = 20,
    bool onlyUnread = false,
  }) async {
    final uri = Uri.parse('${_api.baseUrl}/users/$userId/notifications')
        .replace(
          queryParameters: {
            'page': '$page',
            'pageSize': '$pageSize',
            if (onlyUnread) 'status': 'unread',
          },
        );

    final body = await _api.get(uri) ?? const {};
    final data = (body['data'] as List<dynamic>? ?? const []);
    final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
    return NotificationPage(
      items: data
          .map((e) => NotifCardData.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: (meta['hasMore'] as bool?) ?? data.length >= pageSize,
    );
  }

  @override
  Future<void> markAllAsRead({required String userId}) => _api.post(
    Uri.parse('${_api.baseUrl}/users/$userId/notifications/read-all'),
  );

  @override
  Future<void> markAllAsUnread({required String userId}) => _api.post(
    Uri.parse('${_api.baseUrl}/users/$userId/notifications/unread-all'),
  );

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) => _api.post(
    Uri.parse(
      '${_api.baseUrl}/users/$userId/notifications/$notificationId/read',
    ),
  );

  @override
  Future<void> approve({
    required String userId,
    required String notificationId,
  }) => _api.post(
    Uri.parse(
      '${_api.baseUrl}/users/$userId/notifications/$notificationId/approve',
    ),
  );

  @override
  Future<void> deny({required String userId, required String notificationId}) =>
      _api.post(
        Uri.parse(
          '${_api.baseUrl}/users/$userId/notifications/$notificationId/deny',
        ),
      );

  @override
  void dispose() => _api.dispose();
}

/// In-memory stand-in used until a real backend exists. Same interface,
/// same pagination/read/error shape as `ApiNotificationRepository`, so
/// swapping it out later is a one-line change and won't touch the screen.
///
/// Seed data:
///  - `ntf_1` is `status: NotifStatus.read` and `isDefaultActive: true` —
///    it opens as the selected/active card, but is filtered out when
///    "Only show unread" is toggled on (since it's read).
///  - `ntf_2` and `ntf_3` are `unread` and not default-active — plain
///    cards on open, but remain visible when the unread filter is on.
class MockNotificationRepository implements NotificationRepository {
  final List<NotifCardData> _seed = () {
    final now = DateTime.now();
    return [
      NotifCardData(
        id: 'ntf_1',
        title: 'Test new messaging for SMB market',
        date: DateTime(now.year, now.month, now.day),
        status: NotifStatus.read,
        isDefaultActive: true,
        badgeBold: 'Company Overview: ',
        badgeNormal: 'Priorities',
        lines: [
          NotifActivityLine(
            person: const NotifPerson(
              initials: 'BC',
              avatarColor: Color(0xFF7C6FE8),
              avatarUrl: 'https://i.pravatar.cc/100?img=12',
            ),
            boldName: 'Brian Cervino',
            leadingIcon: Icons.access_time,
            subActionText: 'Added a due date of Aug 10 at 6:00 PM',

            subIcon: Icons.access_time,
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            subTimestamp: now.subtract(
              const Duration(days: 1, hours: 3, minutes: 59),
            ),
          ),
        ],
      ),
      NotifCardData(
        id: 'ntf_2',
        title: 'Sign up for:',
        date: DateTime(now.year, now.month, now.day),
        status: NotifStatus.unread,
        isDefaultActive: false,
        highlighted: true,
        badgeBold: 'New Hire Onboarding: ',
        badgeNormal: 'On First Day - First Week',
        subBadgeBold: '',
        subBadgeNormal: '',
        lines: [
          NotifActivityLine(
            person: const NotifPerson(
              initials: 'CD',
              avatarColor: Color(0xFF6C5CE7),
              avatarUrl: 'https://i.pravatar.cc/100?img=13',
            ),
            boldName: 'Corey Davis',
            leadingIcon: Icons.person_add_alt,
            actionText: 'Added you',
            subIcon: Icons.access_time,
            subActionText: 'Added a due date of Jul 27 at 6:00 PM',
            timestamp: now.subtract(const Duration(days: 1, hours: 4)),
            subTimestamp: now.subtract(
              const Duration(days: 1, hours: 3, minutes: 59),
            ),
          ),
        ],
      ),
      NotifCardData(
        id: 'ntf_3',
        title: "Event's Team",
        date: DateTime(now.year, now.month, now.day),
        status: NotifStatus.unread,
        isDefaultActive: false,
        badgeBold: 'Collaboration Board: ',
        badgeNormal: "Team's",
        hasPromo: true,
        requiresAction: true,
        lines: [
          NotifActivityLine(
            person: const NotifPerson(
              initials: 'LL',
              avatarColor: Color(0xFFE8A0D0),
              avatarUrl: 'https://i.pravatar.cc/100?img=14',
            ),
            boldName: 'Lucy Livingstone',
            actionText: 'has requested to edit the file Zendoor Illustration',
            timestamp: now.subtract(const Duration(hours: 20)),
            metaLabel: "Event's Team",
          ),
        ],
        linkPreview: const LinkPreviewData(
          label: 'Marketing designs',
          url: 'https://www.earthfund.io',
        ),
      ),
    ];
  }();

  @override
  Future<NotificationPage> fetchNotifications({
    required String userId,
    int page = 1,
    int pageSize = 20,
    bool onlyUnread = false,
  }) async {
    // Simulated latency so loading states are exercised in dev/demo too.
    await Future.delayed(const Duration(milliseconds: 400));
    final filtered = onlyUnread
        ? _seed.where((n) => n.status == NotifStatus.unread).toList()
        : _seed;
    final start = (page - 1) * pageSize;
    if (start >= filtered.length) {
      return const NotificationPage(items: [], hasMore: false);
    }
    final end = (start + pageSize).clamp(0, filtered.length);
    return NotificationPage(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<void> markAllAsRead({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (var i = 0; i < _seed.length; i++) {
      _seed[i] = _seed[i].copyWith(status: NotifStatus.read);
    }
  }

  @override
  Future<void> markAllAsUnread({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (var i = 0; i < _seed.length; i++) {
      _seed[i] = _seed[i].copyWith(status: NotifStatus.unread);
    }
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _seed.indexWhere((n) => n.id == notificationId);
    if (i != -1) _seed[i] = _seed[i].copyWith(status: NotifStatus.read);
  }

  @override
  Future<void> approve({
    required String userId,
    required String notificationId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _seed.indexWhere((n) => n.id == notificationId);
    if (i != -1) {
      _seed[i] = _seed[i].copyWith(
        status: NotifStatus.read,
        requiresAction: false,
      );
    }
  }

  @override
  Future<void> deny({
    required String userId,
    required String notificationId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _seed.removeWhere((n) => n.id == notificationId);
  }

  @override
  void dispose() {}
}

// ── Notification settings popup ────────────────────────────────────────
//
// Opened from the "⋮" icon in the title row. Purely a settings dialog for
// how/when notifications are delivered (Never / Periodically / Instantly),
// a desktop-notifications toggle, and a link out to a fuller settings
// screen. It doesn't touch the feed's own state — callbacks are provided
// so the caller can persist changes (repository call, local prefs, etc.)
// without this widget needing to know how that works.

enum NotificationFrequency { never, periodically, instantly }

class NotificationSettingsPopup extends StatefulWidget {
  final ThemeConst colors;
  final NotificationFrequency initialFrequency;
  final bool initialDesktopEnabled;
  final ValueChanged<NotificationFrequency>? onFrequencyChanged;
  final ValueChanged<bool>? onDesktopToggle;
  final VoidCallback? onAllSettingsTap;

  const NotificationSettingsPopup({
    super.key,
    required this.colors,
    this.initialFrequency = NotificationFrequency.periodically,
    this.initialDesktopEnabled = true,
    this.onFrequencyChanged,
    this.onDesktopToggle,
    this.onAllSettingsTap,
  });

  @override
  State<NotificationSettingsPopup> createState() =>
      _NotificationSettingsPopupState();
}

class _NotificationSettingsPopupState extends State<NotificationSettingsPopup> {
  late NotificationFrequency _frequency;
  late bool _desktopEnabled;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _desktopEnabled = widget.initialDesktopEnabled;
  }

  Widget _radioOption(String label, NotificationFrequency value) {
    final c = widget.colors;
    final selected = _frequency == value;
    return InkWell(
      onTap: () {
        setState(() => _frequency = value);
        widget.onFrequencyChanged?.call(value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.primaryColor : c.primaryColor,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 9.r,
                        height: 9.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: c.labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications settings',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: c.primaryColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 20.r, color: c.textColor),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _radioOption('Never', NotificationFrequency.never),
            _radioOption('Periodically', NotificationFrequency.periodically),
            _radioOption('Instantly', NotificationFrequency.instantly),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Allow push notifications',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: c.labelColor,
                    ),
                  ),
                ),
                ToggleSwitch(
                  value: _desktopEnabled,
                  activeColor: Colors.green,
                  colors: c,
                  onTap: () {
                    setState(() => _desktopEnabled = !_desktopEnabled);
                    widget.onDesktopToggle?.call(_desktopEnabled);
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: c.dividerColor),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'All notification settings',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: c.labelColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSetting(userId: ''),
                      ),
                    );
                    // widget.onAllSettingsTap?.call();
                  },
                  borderRadius: BorderRadius.circular(30.r),
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.highlightBoxBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16.r,
                      color: c.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen ───────────────────────────────────────────────────────────────

enum _LoadState { loading, loaded, error, empty }

class NotificationStart extends StatefulWidget {
  final String userId;

  /// Data source for this screen. Defaults to [MockNotificationRepository]
  /// (no URL, no network — works out of the box right now). Swap in
  /// `ApiNotificationRepository(baseUrl: '...')` once a backend exists;
  /// nothing else in this file needs to change.
  final NotificationRepository? repository;

  const NotificationStart({super.key, required this.userId, this.repository});

  @override
  State<NotificationStart> createState() => _NotificationStartState();
}

class _NotificationStartState extends State<NotificationStart> {
  static const _pageSize = 20;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  late final NotificationRepository _repository =
      widget.repository ?? MockNotificationRepository();

  final List<NotifCardData> _notifications = [];
  _LoadState _loadState = _LoadState.loading;
  String? _errorMessage;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  bool _onlyShowUnread = false;
  bool _markingAllAsRead = false;
  String? _selectedCardId;

  /// Ids currently mid-flight on an approve/deny call, so the row can show
  /// a spinner and ignore repeat taps.
  final Set<String> _actionInFlight = {};

  // Notification delivery settings (frequency + desktop toggle), shown in
  // `NotificationSettingsPopup`. Kept here so the choice survives while the
  // screen is alive; wire `_handleFrequencyChanged` / `_handleDesktopToggle`
  // to a repository/prefs call if this needs to persist across sessions.
  NotificationFrequency _notifyFrequency = NotificationFrequency.periodically;
  bool _desktopNotificationsEnabled = true;

  // The 60s "3 minutes ago" -> "4 minutes ago" refresh now lives inside
  // _NotificationListView itself (below), not here. That confines the
  // once-a-minute rebuild to the list, so the app bar, drawer, bottom nav,
  // and the mark-all-as-read/toggle row above the list are never touched
  // by a tick that has nothing to do with them.

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (widget.repository == null) _repository.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _loadState != _LoadState.loaded) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  /// Picks which card should be selected by default: the one the API
  /// flagged with `isDefaultActive: true`, if any. Falls back to the
  /// first item in the list only if nothing was flagged, so old data
  /// without the flag still behaves reasonably.
  String? _pickDefaultSelection(List<NotifCardData> items) {
    for (final n in items) {
      if (n.isDefaultActive) return n.id;
    }
    return items.isNotEmpty ? items.first.id : null;
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadState = _LoadState.loading;
      _errorMessage = null;
    });
    try {
      final page = await _repository.fetchNotifications(
        userId: widget.userId,
        page: 1,
        pageSize: _pageSize,
        onlyUnread: _onlyShowUnread,
      );
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(page.items);
        _page = 1;
        _hasMore = page.hasMore;
        _loadState = _notifications.isEmpty
            ? _LoadState.empty
            : _LoadState.loaded;
        // Keep the previous selection only if that card still exists in
        // the (possibly filtered) list; otherwise fall back to whichever
        // card the API flagged as the default-active one.
        if (!_notifications.any((n) => n.id == _selectedCardId)) {
          _selectedCardId = _pickDefaultSelection(_notifications);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadState = _LoadState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final page = await _repository.fetchNotifications(
        userId: widget.userId,
        page: next,
        pageSize: _pageSize,
        onlyUnread: _onlyShowUnread,
      );
      if (!mounted) return;
      setState(() {
        _notifications.addAll(page.items);
        _page = next;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      // Silent fail on pagination — keep what's already on screen and let
      // the user retry by scrolling again; a full-screen error here would
      // be jarring mid-scroll.
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// Toggles the whole list between read and unread. If everything is
  /// already read, tapping the master radio marks everything unread again
  /// — and vice versa — so "checked" and "unchecked" are both reachable
  /// states rather than the radio only ever moving one direction.
  Future<void> _handleToggleMarkAllAsRead() async {
    if (_markingAllAsRead) return;
    final markingAsRead = !_allRead;
    setState(() => _markingAllAsRead = true);
    // Optimistic update so the UI feels instant.
    final previous = List<NotifCardData>.from(_notifications);
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(
          status: markingAsRead ? NotifStatus.read : NotifStatus.unread,
        );
      }
    });
    try {
      if (markingAsRead) {
        await _repository.markAllAsRead(userId: widget.userId);
      } else {
        await _repository.markAllAsUnread(userId: widget.userId);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications
            ..clear()
            ..addAll(previous);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              markingAsRead
                  ? 'Could not mark all as read. Try again.'
                  : 'Could not mark all as unread. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAllAsRead = false);
    }
  }

  /// Approve an action-required notification. Optimistically marks it read
  /// and clears `requiresAction`; shows a confirmation snackbar on success,
  /// or rolls back and shows an error snackbar on failure.
  Future<void> _handleApprove(String id) async {
    if (_actionInFlight.contains(id)) return;
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final previous = _notifications[i];

    setState(() {
      _actionInFlight.add(id);
      _notifications[i] = previous.copyWith(
        status: NotifStatus.read,
        requiresAction: false,
      );
    });
    try {
      await _repository.approve(userId: widget.userId, notificationId: id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request approved.')));
      }
    } catch (_) {
      if (mounted) {
        final j = _notifications.indexWhere((n) => n.id == id);
        setState(() {
          if (j != -1) _notifications[j] = previous;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not approve. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight.remove(id));
    }
  }

  /// Deny an action-required notification. Optimistically removes it from
  /// the list; shows a confirmation snackbar on success, or restores it in
  /// place and shows an error snackbar on failure.
  Future<void> _handleDeny(String id) async {
    if (_actionInFlight.contains(id)) return;
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final previous = _notifications[i];

    setState(() {
      _actionInFlight.add(id);
      _notifications.removeAt(i);
      if (_selectedCardId == id) {
        _selectedCardId = _pickDefaultSelection(_notifications);
      }
    });
    try {
      await _repository.deny(userId: widget.userId, notificationId: id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request denied.')));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          final insertAt = i.clamp(0, _notifications.length);
          _notifications.insert(insertAt, previous);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not deny. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight.remove(id));
    }
  }

  void _selectCard(String id) {
    setState(() => _selectedCardId = _selectedCardId == id ? null : id);
  }

  /// Opens the "⋮" settings popup. Current frequency/desktop-toggle values
  /// are passed in as initial state; on change, they're written back here
  /// so the next time the popup opens it reflects the latest choice. Swap
  /// the bodies of these two handlers for a repository/prefs call if the
  /// choice needs to persist beyond this screen's lifetime.
  void _openNotificationSettings(ThemeConst c) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => NotificationSettingsPopup(
        colors: c,
        initialFrequency: _notifyFrequency,
        initialDesktopEnabled: _desktopNotificationsEnabled,
        onFrequencyChanged: (freq) {
          setState(() => _notifyFrequency = freq);
        },
        onDesktopToggle: (enabled) {
          setState(() => _desktopNotificationsEnabled = enabled);
        },
        onAllSettingsTap: () {
          // TODO: navigate to the full notification settings screen.
        },
      ),
    );
  }

  List<NotifCardData> get _visibleNotifications {
    if (!_onlyShowUnread) return _notifications;
    return _notifications
        .where((n) => n.status == NotifStatus.unread)
        .toList(growable: false);
  }

  /// True once every notification is read. Drives both the master
  /// "Mark all as read" radio and, per the requirement that every card's
  /// own radio circle light up together with it, each individual
  /// [NotifCard]'s radio too.
  bool get _allRead =>
      _notifications.isNotEmpty &&
      _notifications.every((n) => n.status == NotifStatus.read);

  // ── UI ─────────────────────────────────────────────────────────────

  Widget _titleRow(ThemeConst c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Notification',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: c.primaryColor,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.r, color: c.primaryColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _openNotificationSettings(c),
              child: Icon(Icons.more_vert, size: 20.r, color: c.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topControls(ThemeConst c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 10.h),
      child: Row(
        children: [
          if (_markingAllAsRead)
            SizedBox(
              width: 16.r,
              height: 16.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(c.primaryColor),
              ),
            )
          else
            RadioSelector(
              selected: _allRead,
              onTap: _handleToggleMarkAllAsRead,
              colors: c,
            ),
          SizedBox(width: 8.w),
          Text(
            'Mark all as read',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: c.primaryColor,
            ),
          ),
          const Spacer(),
          Text(
            'Only show unread',
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: c.textColor,
            ),
          ),
          SizedBox(width: 8.w),
          ToggleSwitch(
            value: _onlyShowUnread,
            onTap: () {
              setState(() => _onlyShowUnread = !_onlyShowUnread);
              _loadInitial(); // re-query so pagination stays correct server-side
            },
            colors: c,
          ),
        ],
      ),
    );
  }

  Widget _body(ThemeConst c) {
    switch (_loadState) {
      case _LoadState.loading:
        return Center(child: CircularProgressIndicator(color: c.primaryColor));
      case _LoadState.error:
        return _ErrorState(
          message: _errorMessage ?? 'Something went wrong.',
          onRetry: _loadInitial,
          colors: c,
        );
      case _LoadState.empty:
        return _EmptyState(colors: c);
      case _LoadState.loaded:
        // The server/master list isn't empty, but the *filtered* view can
        // still end up with nothing to show — e.g. "Only show unread" is on
        // and "Mark all as read" just flipped every card to read. That used
        // to fall straight into `_NotificationListView` with zero items,
        // which rendered a totally blank body instead of telling the user
        // why there's nothing here.
        if (_visibleNotifications.isEmpty) {
          return _EmptyState(
            colors: c,
            message: _onlyShowUnread
                ? 'No unread notifications to show.'
                : "You're all caught up",
          );
        }
        return _NotificationListView(
          items: _visibleNotifications,
          hasMore: _hasMore,
          isLoadingMore: _isLoadingMore,
          selectedId: _selectedCardId,
          actionInFlight: _actionInFlight,
          allRead: _allRead,
          colors: c,
          scrollController: _scrollController,
          onRefresh: _loadInitial,
          onSelect: _selectCard,
          onApprove: _handleApprove,
          onDeny: _handleDeny,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeConst.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.pageBg,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titleRow(c),
            _topControls(c),
            Expanded(child: _body(c)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }
}

/// Owns the actual scrolling list, isolated from [_NotificationStartState]
/// for one reason: the once-a-minute "3 minutes ago" -> "4 minutes ago"
/// refresh. That tick only needs to touch the visible card labels — it has
/// no business rebuilding the app bar, drawer, bottom nav, or the toggle
/// row above the list. Keeping its own `Timer` here means `setState` on
/// tick only re-runs this widget's `build`, not the whole screen's.
///
/// Beyond that scoping, a few `ListView` knobs are tuned for a feed that's
/// already RepaintBoundary'd per item:
///  - `addRepaintBoundaries: false` — each item wraps itself in its own
///    `RepaintBoundary` keyed by id already, so the framework doesn't need
///    to add a second one per item.
///  - `addAutomaticKeepAlives: false` — cards don't hold state that needs
///    preserving when scrolled offscreen, so keeping them alive just wastes
///    memory on a long/paginated feed.
///  - `cacheExtent` — pre-builds a bit past the visible viewport so fast
///    scrolls and the infinite-scroll trigger don't show a blank flash.
class _NotificationListView extends StatefulWidget {
  final List<NotifCardData> items;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedId;
  final Set<String> actionInFlight;
  final bool allRead;
  final ThemeConst colors;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(String id) onSelect;
  final void Function(String id) onApprove;
  final void Function(String id) onDeny;

  const _NotificationListView({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.selectedId,
    required this.actionInFlight,
    required this.allRead,
    required this.colors,
    required this.scrollController,
    required this.onRefresh,
    required this.onSelect,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<_NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<_NotificationListView> {
  Timer? _relativeTimeTicker;

  @override
  void initState() {
    super.initState();
    _relativeTimeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final items = widget.items;
    return RefreshIndicator(
      color: c.primaryColor,
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 20.h),
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 800,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        itemCount: items.length + (widget.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 14.h),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: widget.isLoadingMore
                    ? CircularProgressIndicator(color: c.primaryColor)
                    : const SizedBox.shrink(),
              ),
            );
          }
          final data = items[index];
          return RepaintBoundary(
            key: ValueKey(data.id),
            child: NotifCard(
              data: data,
              isSelected: widget.selectedId == data.id,
              onSelect: () => widget.onSelect(data.id),
              colors: c,
              isActionInFlight: widget.actionInFlight.contains(data.id),
              onApprove: () => widget.onApprove(data.id),
              onDeny: () => widget.onDeny(data.id),
              forceRadioActive: widget.allRead,
            ),
          );
        },
      ),
    );
  }
}

// ── Shared color palette, kept in one immutable object so child widgets
// can take it as a plain constructor arg instead of reaching into State ──

class ThemeConst {
  final Color primaryColor;
  final Color textColor;
  final Color labelColor;
  final Color dividerColor;
  final Color greenColor;
  final Color toggleOffColor;
  final Color badgePurple;
  final Color pageBg;
  final Color shadowBlack08;
  final Color darkCardBg;
  final Color darkCardSubBg;
  final Color zendoorPurple;

  /// Box background for cards with `highlighted: true` (e.g. ntf_2) —
  /// distinct from the plain white default box (e.g. ntf_1). Cleared back
  /// to the default once every notification is marked read.
  final Color highlightBoxBg;

  const ThemeConst({
    this.primaryColor = const Color(0xFF0A0258),
    this.textColor = const Color(0xFF6C7278),
    this.labelColor = const Color(0xFF303030),
    this.dividerColor = const Color(0xFFE4E7EC),
    this.greenColor = const Color(0xFF1DC230),
    this.toggleOffColor = const Color(0xFF676299),
    this.badgePurple = const Color(0xFF4B44B0),
    this.pageBg = const Color(0xFFF6F7FB),
    this.shadowBlack08 = const Color(0x14000000),
    this.darkCardBg = const Color(0xFF15104A),
    this.darkCardSubBg = const Color(0xFF1E1962),
    this.zendoorPurple = const Color(0xFF4F3FA8),
    this.highlightBoxBg = const Color(0xFFF3F1FC),
  });

  static const ThemeConst of_ = ThemeConst();
  static ThemeConst of(BuildContext context) => of_;
}

// ── Small reusable controls ────────────────────────────────────────────

class ToggleSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  final ThemeConst colors;

  /// Color used for the track border + thumb when [value] is true.
  /// Defaults to [ThemeConst.greenColor] (the "Only show unread" toggle's
  /// look); pass [ThemeConst.primaryColor] or similar for a purple/indigo
  /// toggle like the one in the notification settings popup.
  final Color? activeColor;

  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onTap,
    required this.colors,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = activeColor ?? colors.greenColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 30.w,
        height: 15.h,
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: value ? onColor : colors.toggleOffColor,
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14.w,
            height: 14.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? onColor : colors.toggleOffColor,
            ),
          ),
        ),
      ),
    );
  }
}

class RadioSelector extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final ThemeConst colors;

  const RadioSelector({
    super.key,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 16.r,
        height: 16.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.greenColor : Colors.white,
          border: Border.all(
            color: selected ? colors.greenColor : colors.toggleOffColor,
            width: 1.4,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 10.r, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Gradient "Approve" / outlined "Deny" pill pair shown on action-required
/// notifications (e.g. edit-access requests).
class ApproveDenyButtons extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  final bool isLoading;
  final ThemeConst colors;

  /// Width of each button. If null, buttons size to fit their label
  /// (no forced stretching). Set a value (e.g. 90) to make both buttons
  /// a fixed, controlled width instead of filling the row.
  final double? buttonWidth;

  /// Height of each button.
  final double buttonHeight;

  /// Horizontal gap between the two buttons.
  final double gap;

  /// Font size for the button labels (in .sp units).
  final double fontSize;

  const ApproveDenyButtons({
    super.key,
    required this.onApprove,
    required this.onDeny,
    required this.colors,
    this.isLoading = false,
    this.buttonWidth, // null = auto-size to content
    this.buttonHeight = 30,
    this.gap = 5,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final approveBtn = _PillButton(
      label: 'Approve',
      onTap: isLoading ? null : onApprove,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFFB57BFF), Color(0xFF3EC6E0)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      textColor: Colors.white,
      height: buttonHeight.h,
      fontSize: fontSize,
    );
    final denyBtn = _PillButton(
      label: 'Deny',
      onTap: isLoading ? null : onDeny,
      isLoading: false,
      backgroundColor: Colors.white,
      borderColor: colors.primaryColor,
      textColor: colors.primaryColor,
      height: buttonHeight.h,
      fontSize: fontSize,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
      child: Row(
        mainAxisSize: MainAxisSize.min, // row only as wide as its children
        children: [
          buttonWidth != null
              ? SizedBox(width: buttonWidth!.w, child: approveBtn)
              : approveBtn,
          SizedBox(width: gap.w),
          buttonWidth != null
              ? SizedBox(width: buttonWidth!.w, child: denyBtn)
              : denyBtn,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final double fontSize;
  final double height;

  const _PillButton({
    required this.label,
    required this.onTap,
    required this.textColor,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.fontSize = 10, // default, in .sp units
    this.height = 30, // default, in raw px (already .h-scaled by caller)
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? (backgroundColor ?? Colors.white) : null,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.2)
              : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 12.r,
                height: 12.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(textColor),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: fontSize.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

/// Avatar with cached network loading + graceful fallback to initials
/// (loading, missing URL, or fetch failure all land on the same avatar).
class Avatar extends StatelessWidget {
  final NotifPerson person;

  const Avatar({super.key, required this.person});

  Widget _initials() {
    return CircleAvatar(
      radius: 14.r,
      backgroundColor: person.avatarColor,
      child: Text(
        person.initials,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = person.avatarUrl;
    if (url == null || url.isEmpty) return _initials();
    // Avatars render at a fixed 28.r, but source images from an API are
    // routinely 100-800px+. Without a cache size hint, every decode costs
    // whatever the source resolution is, on every card, every scroll pass.
    // Capping the decode target at ~3x the render size (covers up to a
    // 3x device pixel ratio) keeps memory and CPU proportional to what's
    // actually on screen instead of to whatever the backend happens to send.
    final cacheSize = (28.r * 3).round();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 28.r,
        height: 28.r,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) => _initials(),
        errorWidget: (context, _, __) => _initials(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ThemeConst colors;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 36.r, color: colors.textColor),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: colors.textColor,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeConst colors;
  final String message;
  const _EmptyState({
    required this.colors,
    this.message = "You're all caught up",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 36.r, color: colors.textColor),
          SizedBox(height: 10.h),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13.sp, color: colors.textColor),
          ),
        ],
      ),
    );
  }
}

class LinkPreview extends StatelessWidget {
  final LinkPreviewData data;
  final ThemeConst colors;

  const LinkPreview({super.key, required this.data, required this.colors});

  Future<void> _openLink(BuildContext context) async {
    debugPrint('LinkPreview tapped: ${data.url}');
    final uri = Uri.tryParse(data.url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      debugPrint('LinkPreview: URL failed to parse -> ${data.url}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("This link isn't valid.")));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    debugPrint('LinkPreview: launchUrl returned $launched');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openLink(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LINK PREVIEW',
              style: GoogleFonts.inter(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: colors.textColor,
              ),
            ),
            SizedBox(height: 6.h),
            Divider(height: 1, color: colors.dividerColor),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link, size: 14.r, color: colors.textColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${data.label} ',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: colors.labelColor,
                          ),
                        ),
                        TextSpan(
                          text: data.url,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF3B82F6),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ZendoorPromoBox extends StatelessWidget {
  final ThemeConst colors;
  const ZendoorPromoBox({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.zendoorPurple,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'Z',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zendoor Illustrations',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Join the Zendoor community and become a part of the '
                  "solution to some of humanity's most pressing problems.",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityLineWidget extends StatelessWidget {
  final NotifActivityLine line;
  final ThemeConst colors;

  const ActivityLineWidget({
    super.key,
    required this.line,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final actionTimeText = RelativeTime.format(line.timestamp);
    final subTimeText = line.subTimestamp != null
        ? RelativeTime.format(line.subTimestamp!)
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(person: line.person),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.boldName,
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.labelColor,
                  ),
                ),

                if (line.actionText != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (line.leadingIcon != null) ...[
                          Container(
                            width: 18.r,
                            height: 18.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.dividerColor,
                            ),
                            child: Icon(
                              line.leadingIcon,
                              size: 11.r,
                              color: colors.textColor,
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: line.actionText,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: colors.labelColor,
                                  ),
                                ),
                                // Only append the time here when there's
                                // no metaLabel row below to show it —
                                // otherwise it duplicates (and the extra
                                // words push "hours ago" onto its own
                                // wrapped line).
                                if (line.metaLabel == null)
                                  TextSpan(
                                    text: '  $actionTimeText',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w400,
                                      color: colors.textColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (line.metaLabel != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sell,
                          size: 15.r,
                          color: const Color(0xFFD6249F),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: actionTimeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w400,
                                    color: colors.textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '  |  ',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w400,
                                    color: colors.dividerColor,
                                  ),
                                ),
                                TextSpan(
                                  text: line.metaLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w400,
                                    color: colors.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (line.subActionText != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18.r,
                          height: 18.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.dividerColor,
                          ),
                          child: Icon(
                            line.subIcon ?? Icons.access_time,
                            size: 11.r,
                            color: colors.textColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.subActionText!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: colors.labelColor,
                                ),
                              ),
                              if (subTimeText != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    subTimeText,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w400,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single notification card. Renders either the plain-white or the
/// dark-highlighted variant depending on [isSelected], mirroring the
/// original design's radio-group behavior — but now driven by the card's
/// stable `id` (from the API) rather than a list index, so selection stays
/// correct across pagination/refresh.
///
/// When `data.requiresAction` is true, renders an Approve / Deny row
/// beneath the activity lines / promo box and above the link preview.
class NotifCard extends StatelessWidget {
  final NotifCardData data;
  final bool isSelected;
  final VoidCallback onSelect;
  final ThemeConst colors;
  final bool isActionInFlight;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  /// When true, this card's own radio circle shows checked regardless of
  /// [isSelected] — driven by "Mark all as read" being active for the
  /// whole list, so every card's radio lights up together with it.
  final bool forceRadioActive;

  const NotifCard({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onSelect,
    required this.colors,
    this.isActionInFlight = false,
    this.onApprove,
    this.onDeny,
    this.forceRadioActive = false,
  });

  Widget _badgeText(String bold, String normal, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: bold,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color ?? colors.badgePurple,
              ),
            ),
            TextSpan(
              text: normal,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: color ?? colors.badgePurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required bool dark}) {
    final titleColor = dark ? Colors.white : colors.labelColor;
    final dateColor = dark ? Colors.white70 : colors.textColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12.r, color: dateColor),
                  SizedBox(width: 4.w),
                  Text(
                    RelativeTime.shortDate(data.date),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: dateColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        RadioSelector(
          selected: isSelected || forceRadioActive,
          onTap: onSelect,
          colors: colors,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubBadge =
        (data.subBadgeBold != null && data.subBadgeBold!.isNotEmpty) ||
        (data.subBadgeNormal != null && data.subBadgeNormal!.isNotEmpty);
    final hasBadge = data.badgeBold.isNotEmpty || data.badgeNormal.isNotEmpty;

    // A card is "active" (dark header + border) whenever it's the
    // currently selected card. Checking "Mark all as read" makes every
    // card go active the same way — not just light up its radio circle —
    // so the whole list visually matches once all are read.
    final active = isSelected || forceRadioActive;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            decoration: BoxDecoration(
              color: colors.darkCardBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9.r),
                topRight: Radius.circular(9.r),
              ),
            ),
            child: _header(dark: true),
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
            child: _header(dark: false),
          ),
        if (active) SizedBox(height: 0) else SizedBox(height: 6.h),
        if (active && hasSubBadge)
          Container(
            width: double.infinity,
            color: colors.darkCardSubBg,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: data.subBadgeBold,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: data.subBadgeNormal,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (hasBadge)
          _badgeText(data.badgeBold, data.badgeNormal),
        Divider(height: 1, color: colors.dividerColor),
        ...data.lines.map((l) => ActivityLineWidget(line: l, colors: colors)),
        if (data.hasPromo) ZendoorPromoBox(colors: colors),
        if (data.linkPreview != null)
          LinkPreview(data: data.linkPreview!, colors: colors),
        if (active) SizedBox(height: 4.h),
        if (data.requiresAction && onApprove != null && onDeny != null)
          ApproveDenyButtons(
            onApprove: onApprove!,
            onDeny: onDeny!,
            isLoading: isActionInFlight,
            colors: colors,
            buttonWidth:
                90, // control button width here — remove/null to auto-size
          ),
      ],
    );

    // The plain white box is the default. A card with `highlighted: true`
    // gets a distinct tinted box — but once every notification is marked
    // read (forceRadioActive), all boxes fall back to that same default
    // white, regardless of their own highlighted flag.
    final useHighlightBg = data.highlighted && !forceRadioActive;

    return Container(
      decoration: BoxDecoration(
        color: useHighlightBg ? colors.highlightBoxBg : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: active
            ? Border.all(color: colors.primaryColor, width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowBlack08,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}
