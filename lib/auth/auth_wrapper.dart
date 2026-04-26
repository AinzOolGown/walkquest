import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseshop/complete_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../enemy_selection_page.dart';
import '../home_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                userSnapshot.data!.data() as Map<String, dynamic>?;

            final isComplete = data?['profileComplete'] ?? false;

            if (!isComplete) {
              return const CompleteProfilePage();
            }

            final hasEnemy = data?['hasActiveEnemy'] ?? false;

            if (!hasEnemy) {
              return const EnemySelectionPage();
            }

            return const HomePage();
          },
        );
      },
    );
  }
}