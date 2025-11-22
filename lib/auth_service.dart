import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Sign In dengan Email/Password (Sudah Ada)
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; 
    } on FirebaseAuthException catch (e) {
      return e.message; 
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Sign In dengan Google
  Future<String?> signInWithGoogle() async {
    try {
      // Mulai proses interaktif Google Sign In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return 'Login Google dibatalkan.'; // Pengguna membatalkan proses
      }

      // Mendapatkan kredensial dari Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase dengan kredensial Google
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      // Ini sering terjadi jika konfigurasi Android/iOS belum lengkap
      return 'Gagal Sign In Google. Pastikan konfigurasi platform sudah benar: ${e.toString()}';
    }
  }

  // 3. Sign In dengan Nomor Telepon (Hanya bagian inisiasi)
  // Catatan: Ini lebih kompleks dan membutuhkan penanganan State di UI
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(PhoneAuthCredential) verificationCompleted,
    Function(FirebaseAuthException) verificationFailed,
    Function(String, int?) codeSent,
    Function(String) codeAutoRetrievalTimeout,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }
}
