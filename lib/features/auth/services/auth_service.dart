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

    String uid = userCredential.user!.uid;
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
    } on FirebaseException catch (e) {
      rethrow;
    }
  }

  // ADDED: Optional callback to ask the UI for confirmation if it's a new user
  Future<void> singInWithGoogle({
    Future<bool> Function()? onConfirmRegistration,
  }) async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '706499653261-2rt59tfu887s12tdo0s7iea03emhke70.apps.googleusercontent.com',
      );

      // Force sign out to clear stale tokens/reauth state
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

      // CHECK IF NEW USER
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // If a callback was provided, ask the UI for permission
        if (onConfirmRegistration != null) {
          bool proceed = await onConfirmRegistration();
          if (!proceed) {
            // User canceled! Delete the accidental Auth record and abort.
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
    try {
      String trimmedEmail = email.trim();
      String trimmedPassword = password.trim();

      // Check for Admin Credentials
      if (trimmedEmail == 'admin@gmail.com' && trimmedPassword == 'admin123') {
        return 'admin';
      }

      await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      return 'user';
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // 1. Sign out from Firebase
      await _auth.signOut();

      // 2. Sign out/disconnect from Google Sign-In session
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
