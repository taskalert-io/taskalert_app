import 'package:flutter/material.dart';

/// Global navigator key so non-widget code (e.g. `AuthInterceptor`, which
/// has no `BuildContext` of its own) can still trigger navigation — used to
/// force the user back to Sign In when their session expires and the
/// refresh token can't renew it.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
