import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/DashboardPage.dart';
import 'package:taskalert_app/screens/LoginPage.dart';
import 'package:taskalert_app/screens/SplashScreen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final storage = const FlutterSecureStorage();
    String? isLoggedIn = await storage.read(key: 'isLoggedIn');
    String? token = await storage.read(key: 'accessToken');

    if (isLoggedIn == 'true' && token != null) {
      return DashboardPage(); // replace with your main/home screen
      // return const ImagePickerScreen(); // fallback to image picker screen
    } else {
      // return const LoginPage(); // replace with your login screen
      return SplashScreen(); // Show splash screen first
    }
  }


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // You can set this to 1.0 to disable all scaling,
        // or a maximum value like 1.2 to limit it.
        textScaler: const TextScaler.linear(1.0),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
        // theme: ThemeData(
        //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // ),
        home: FutureBuilder<Widget>(
          future: _getInitialScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen();
            } else if (snapshot.hasData) {
              return snapshot.data!;
            } else {
              return LoginPage(); // fallback
            }
          },
        ),
      ),
    );
  }
}

