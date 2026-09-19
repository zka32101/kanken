import 'package:firebase_auth/firebase_auth.dart';

/// 認証まわりの処理をまとめたサービス
///
/// 小学生ユーザー向けに、メール登録の手間を省いた匿名認証を採用する。
/// 端末を変える場合の引き継ぎ機能は将来的な拡張とする。
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 未ログインなら匿名でサインインし、ログイン済みならそのユーザーを返す
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('匿名サインインに失敗しました');
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
