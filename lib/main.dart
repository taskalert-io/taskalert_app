import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/HomeScreen.dart';
import 'package:taskalert_app/screens/SignInScreen.dart';
import 'package:taskalert_app/screens/SplashScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart' as di;

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize dependency injection
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();

    /// CACHE THE FUTURE ONLY ONCE
    _initialScreenFuture = _getInitialScreen();
  }

  Future<Widget> _getInitialScreen() async {
    final storage = di.sl<FlutterSecureStorage>();
    // 'auth_token' is the key actually written on successful login/signup
    // (see AuthRepositoryImpl) and read by AuthInterceptor on every request,
    // so its presence is the source of truth for an active session.
    final token = await storage.read(key: 'auth_token');
    final userId = await storage.read(key: 'user_id');

    if (token != null && token.isNotEmpty) {
      return HomeScreen(userId: userId ?? '');
    } else {
      return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),

          child: MaterialApp(
            title: 'taskalert.io',
            debugShowCheckedModeBanner: false,

            navigatorObservers: [routeObserver],

            theme: ThemeData(textTheme: GoogleFonts.interTextTheme()),

            home: FutureBuilder<Widget>(
              future: _initialScreenFuture,

              builder: (context, snapshot) {
                /// LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                /// SUCCESS
                if (snapshot.hasData) {
                  return snapshot.data!;
                }

                /// FALLBACK
                return const SignInScreen();
              },
            ),
          ),
        );
      },
    );
  }
}
