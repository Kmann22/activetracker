import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up method
  static Future<void> signUp(String email, String password, String name) async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user's profile with provided name
      await userCredential.user?.updateProfile(displayName: name);
      await userCredential.user?.reload();

      // Optionally: Add additional user data to Firestore or Realtime Database
      // await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
      //   'name': name,
      //   'email': email,
      // });
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      switch (e.code) {
        case 'weak-password':
          throw 'The password provided is too weak.';
        case 'email-already-in-use':
          throw 'The account already exists for that email.';
        default:
          throw 'An unknown error occurred.';
      }
    } catch (e) {
      throw 'An error occurred: $e';
    }
  }

  // Sign in method
  static Future<void> signIn(String email, String password) async {
    try {
      // Sign in user with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided for that user.';
        default:
          throw 'An unknown error occurred.';
      }
    } catch (e) {
      throw 'An error occurred: $e';
    }
  }
}
