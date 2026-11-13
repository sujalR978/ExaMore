import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prep_mate/features/auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email & Password Registration
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String? adminId,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? firebaseUser = userCredential.user;
    if (firebaseUser == null) return;

    await firebaseUser.sendEmailVerification();

    String uid = firebaseUser.uid;
    UserModel user = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      adminId: adminId,
      loginMethod: 'register',
      photoUrl: 'assets/image/L_image.png',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _firestore.collection('users').doc(uid).set(user.toMap());
    } on FirebaseException {
      rethrow;
    } finally {
      await _auth.signOut();
    }
  }

  // Google Sign-In with dynamic Instructor Code linking
  Future<Map<String, dynamic>> signInWithGoogle({
    Future<String?> Function()? onGetAdminId,
  }) async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '706499653261-2rt59tfu887s12tdo0s7iea03emhke70.apps.googleusercontent.com',
      );

      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        throw Exception('sign_in_canceled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception("Google Auth ID Token is null.");
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User firebaseUser = userCredential.user!;

      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // Check if user document already exists in Firestore
      final docSnap = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      String? linkedAdminId;
      String resolvedRole = 'student';

      if (docSnap.exists) {
        final data = docSnap.data();
        resolvedRole = (data?['role'] ?? 'student').toString().toLowerCase();
        linkedAdminId = data?['adminId'];
      } else if (isNewUser || !docSnap.exists) {
        // First-time user: collect instructor ID through dialog callback
        if (onGetAdminId != null) {
          linkedAdminId = await onGetAdminId();
          if (linkedAdminId == null) {
            // User cancelled the modal dialog
            await firebaseUser.delete();
            await GoogleSignIn.instance.signOut();
            throw Exception('sign_in_canceled');
          }
        }
      }

      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Student',
        email: firebaseUser.email ?? '',
        role: resolvedRole,
        adminId: linkedAdminId,
        loginMethod: 'google',
        photoUrl: firebaseUser.photoURL ?? 'assets/image/L_image.png',
        createdAt: docSnap.exists
            ? (docSnap.data()?['createdAt'] != null
                  ? (docSnap.data()!['createdAt'] as Timestamp).toDate()
                  : DateTime.now())
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap(), SetOptions(merge: true));

      return {
        'role': resolvedRole,
        'uid': firebaseUser.uid,
        'adminId': linkedAdminId,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>> singInWithGoogle({
    Future<String?> Function()? onGetAdminId,
  }) => signInWithGoogle(onGetAdminId: onGetAdminId);

  // Email & Password Login
  Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    final String trimmedEmail = email.trim().toLowerCase();
    final String trimmedPassword = password.trim();

    UserCredential? userCredential;

    try {
      userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Email is not registered.',
        );
      }
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
        );
      }
      rethrow;
    }

    final User? user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Email is not registered.',
      );
    }

    final String uid = user.uid;

    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User profile not found. Please register again.',
      );
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String role = (userData['role'] ?? 'student')
        .toString()
        .toLowerCase();
    final String? adminId = userData['adminId'];

    // Email verification check (Super Admin excluded if flagged in DB)
    await user.reload();
    if (!user.emailVerified && role != 'super_admin') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Please verify your email before logging in. Check your inbox for the link.',
      );
    }

    return {'role': role, 'uid': uid, 'adminId': adminId};
  }

  // Google Play Compliant Account & Data Deletion
  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found to delete.');
    }

    final String uid = user.uid;

    try {
      // 1. Delete user subcollections (saved_exams, attempts)
      final savedExamsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_exams')
          .get();
      for (final doc in savedExamsSnapshot.docs) {
        await doc.reference.delete();
      }

      final attemptsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('attempts')
          .get();
      for (final doc in attemptsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Delete main user document
      await _firestore.collection('users').doc(uid).delete();

      // 3. Delete Firebase Auth user
      await user.delete();

      // 4. Sign out from Google if signed in
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message:
              'For security reasons, please log in again before deleting your account.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
