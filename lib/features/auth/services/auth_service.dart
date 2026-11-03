import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prep_mate/features/Auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? firebaseUser = userCredential.user;
    if (firebaseUser == null) return;

    // 1. Send the email verification link
    await firebaseUser.sendEmailVerification();

    String uid = firebaseUser.uid;
    UserModel user = UserModel(
      uid: uid,
      name: name,
      email: email,
      password: password,
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
      // 2. Sign out immediately so unverified accounts cannot browse the app
      await _auth.signOut();
    }
  }

  Future<void> singInWithGoogle({
    Future<bool> Function()? onConfirmRegistration,
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

      if (isNewUser) {
        if (onConfirmRegistration != null) {
          bool proceed = await onConfirmRegistration();
          if (!proceed) {
            await firebaseUser.delete();
            await GoogleSignIn.instance.signOut();
            throw Exception('sign_in_canceled');
          }
        }
      }

      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        password: '',
        loginMethod: 'google',
        photoUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<String> signInUser({
    required String email,
    required String password,
  }) async {
    String trimmedEmail = email.trim().toLowerCase();
    String trimmedPassword = password.trim();

    // 1. Check for Admin Credentials
    if (trimmedEmail == 'admin@gmail.com' && trimmedPassword == 'admin123') {
      return 'admin';
    }

    // 2. Check if the user document exists in Firestore
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty && trimmedEmail != 'admin@gmail.com') {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Email is not registered.',
      );
    }

    // 3. Attempt Firebase Authentication
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final User? user = userCredential.user;

      // 4. Enforce verification check: reload user to get latest status
      if (user != null) {
        await user.reload();
        if (!user.emailVerified) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message:
                'Please verify your email before logging in. Check your inbox for the link.',
          );
        }
      }

      return 'user';
    } on FirebaseAuthException catch (e) {
      // Preserve explicit error states
      if (e.code == 'email-not-verified') {
        rethrow;
      }
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
        );
      }
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
