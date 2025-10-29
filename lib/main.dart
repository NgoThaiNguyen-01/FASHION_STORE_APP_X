import 'package:flutter/material.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/wishlist_screen.dart';
import 'database/db_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.database;
  await DBHelper.logDbPath();
  runApp(const UngDungThoiTrangTn());
}

class UngDungThoiTrangTn extends StatelessWidget {
  const UngDungThoiTrangTn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T&N Fashion Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.redAccent,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // Màn hình khởi động
      home: const ManHinhChao(),

      // Các route cố định (không cần tham số)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
      },

      // Các route cần tham số: /home, /wishlist
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            final args = (settings.arguments as Map?) ?? {};
            final fullName = (args['fullName'] as String?) ?? 'Người dùng';
            final isAdmin = (args['isAdmin'] as bool?) ?? false;
            final userId = (args['userId'] as int?) ?? 0;

            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                fullName: fullName,
                isAdmin: isAdmin,
                userId: userId,
              ),
            );

          case '/wishlist':
            final args = (settings.arguments as Map?) ?? {};
            final userId = (args['userId'] as int?) ?? 0;

            return MaterialPageRoute(
              builder: (_) => WishlistScreen(userId: userId),
            );
        }

        // Fallback: nếu gọi route lạ → về Home mặc định (demo)
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(
            fullName: 'Người dùng',
            isAdmin: false,
            userId: 0,
          ),
        );
      },
    );
  }
}
