import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prep_mate/features/Admin/screen/adminHomeScreen.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/User/Navigator/mainNavigator.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Examora',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (roleSnapshot.hasError) {
                      return Scaffold(
                        body: Center(
                          child: Text(
                            'Error loading role: ${roleSnapshot.error}',
                          ),
                        ),
                      );
                    }

                    final isHardcodedSuperAdmin =
                        user.email?.toLowerCase() == 'admin@gmail.com';

                    String role = 'student';

                    if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                      final data =
                          roleSnapshot.data!.data() as Map<String, dynamic>?;
                      role = (data?['role'] ?? 'student')
                          .toString()
                          .toLowerCase()
                          .trim();
                    } else if (isHardcodedSuperAdmin) {
                      role = 'super_admin';
                    }

                    // 3-Tier Routing Gate - FIXED
                    if (role == 'super_admin' || role == 'admin') {
                      return const AdminHomeScreen();
                    } else {
                      return const MainNavigator();
                    }
                  },
                );
              }

              return const Login();
            },
          ),
        );
      },
    );
  }
}
