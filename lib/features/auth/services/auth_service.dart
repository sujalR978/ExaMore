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
      print("FIRESTORE INSERT SUCCESS");
    } on FirebaseException catch (e) {
      print("FIRESTORE ERROR CODE: ${e.code}");
      print("FIRESTORE ERROR MESSAGE: ${e.message}");
      rethrow;
    }
  }

  Future<void> singInWithGoogle() async {
    try {
      // Initialize with your Web Client ID
      await GoogleSignIn.instance.initialize(
        serverClientId: '706499653261-2rt59tfu887s12tdo0s7iea03emhke70.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        print("Google Sign In aborted by user.");
        return;
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
          
      print("GOOGLE SIGN IN SUCCESS");
    } catch (e) {
      print("GOOGLE SIGN IN ERROR: $e");
      rethrow;
    }
  }
}