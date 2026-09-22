import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ใช้ uid แทน email เป็นตัวแยกข้อมูลของแต่ละ user (ไม่เปลี่ยน + ใช้กับ Security Rules ได้)
  String? get uid {
    return _auth.currentUser?.uid;
  }

  String? get email {
    return _auth.currentUser?.email;
  }

  // ฟังสถานะ login/logout ใช้ใน main.dart เพื่อสลับหน้า
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  //* คืนค่า null ถ้าสำเร็จ หรือข้อความ error ถ้าไม่สำเร็จ
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Register failed';
    }
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}
