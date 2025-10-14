import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apk_sukorame/src/auth/login_screen.dart';
import 'package:apk_sukorame/src/admin/screens/main_screen.dart';
import 'package:apk_sukorame/src/guest/views/dashboard_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Periksa apakah ada user yang login
          if (snapshot.hasData) {
            final user = snapshot.data;

            // Periksa apakah user adalah tamu anonim
            if (user != null && user.isAnonymous) {
              return const GuestDashboardScreen();
            }
            
            // Periksa apakah user adalah admin yang terverifikasi
            if (user != null && user.emailVerified) {
              return const MainScreen();
            }
          }
          
          // Jika tidak ada user, atau user ada tapi belum verifikasi, tampilkan LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}