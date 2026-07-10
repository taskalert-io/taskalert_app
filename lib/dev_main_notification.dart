import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/NotificationStart.dart';

void main() {
  runApp(const _DevApp());
}

class _DevApp extends StatelessWidget {
  const _DevApp();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(textTheme: GoogleFonts.interTextTheme()),
          // This standalone harness never calls the app's DI setup
          // (`di.init()`), so the screen's default RealNotificationRepository
          // (which pulls `NotificationController` from that DI container)
          // would crash here — force the offline mock repository instead.
          home: NotificationStart(
            userId: 'dev_user',
            repository: MockNotificationRepository(),
          ),
        );
      },
    );
  }
}
