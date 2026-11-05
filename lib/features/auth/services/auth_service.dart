import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prep_mate/features/Auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String superAdminEmail = 'admin@gmail.com';
  static const String superAdminPassword = 'admin123';

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
      password: password,
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
  Future<Map<String, dynamic>> singInWithGoogle({
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

      // Check if user is predefined super admin via Google account
      if (firebaseUser.email?.toLowerCase() == superAdminEmail) {
        resolvedRole = 'super_admin';
        linkedAdminId = null;
      }

      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Student',
        email: firebaseUser.email ?? '',
        password: '',
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

  // Email & Password Login
  Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    final String trimmedEmail = email.trim().toLowerCase();
    final String trimmedPassword = password.trim();

    final bool isSuperAdminCreds =
        (trimmedEmail == superAdminEmail &&
        trimmedPassword == superAdminPassword);

    UserCredential? userCredential;

    // 1. Super Admin Auto-Provisioning & Bypass
    if (isSuperAdminCreds) {
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: trimmedEmail,
              password: trimmedPassword,
            );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final String superAdminUid = userCredential.user!.uid;

      final adminDoc = await _firestore
          .collection('users')
          .doc(superAdminUid)
          .get();

      if (!adminDoc.exists || adminDoc.data()?['role'] != 'super_admin') {
        await _firestore.collection('users').doc(superAdminUid).set({
          'uid': superAdminUid,
          'name': 'Super Admin',
          'email': superAdminEmail,
          'role': 'super_admin',
          'adminId': null,
          'loginMethod': 'password',
          'photoUrl': 'assets/image/L_image.png',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return {'role': 'super_admin', 'uid': superAdminUid, 'adminId': null};
    }

    // 2. Standard User / Admin Login
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

    // Email verification check (Super Admin excluded)
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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
