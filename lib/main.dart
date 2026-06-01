import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/DashboardPage.dart';
import 'package:taskalert_app/screens/SignInScreen.dart';
import 'package:taskalert_app/screens/SplashScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart' as di;

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

void main() {
  di.init(); // Initialize dependency injection
  WidgetsFlutterBinding.ensureInitialized();
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
<<<<<<< HEAD
    final storage = di.sl<FlutterSecureStorage>();
    String? isLoggedIn = await storage.read(key: 'isLoggedIn');
    String? token = await storage.read(key: 'accessToken');
=======
    const storage = FlutterSecureStorage();

    final String? isLoggedIn = await storage.read(
      key: 'isLoggedIn',
    );

    final String? token = await storage.read(
      key: 'accessToken',
    );
>>>>>>> origin

    if (isLoggedIn == 'true' && token != null) {
      return DashboardPage(userId: '');
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
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),

          child: MaterialApp(
            debugShowCheckedModeBanner: false,

            navigatorObservers: [routeObserver],

            theme: ThemeData(
              textTheme: GoogleFonts.interTextTheme(),
            ),

            home: FutureBuilder<Widget>(
              future: _initialScreenFuture,

              builder: (context, snapshot) {
                /// LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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