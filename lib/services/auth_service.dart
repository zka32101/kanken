import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 認証まわりの処理をまとめたサービス
///
/// 小学生ユーザー向けに、メール登録の手間を省いた匿名認証をデフォルトとしつつ、
/// 保護者が端末を変えても引き継げるようGoogleアカウント連携も選べるようにする。
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

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

  /// Googleアカウントでサインインする
  ///
  /// 匿名アカウントで使用中の場合は、既存データを引き継げるようアカウントを
  /// リンクする。そのGoogleアカウントが既に別ユーザーに紐づいている場合は
  /// 通常のサインインにフォールバックする（この場合、匿名アカウントの
  /// データは引き継がれない）。
  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Googleサインインがキャンセルされました');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final currentAuthUser = _auth.currentUser;
    if (currentAuthUser != null && currentAuthUser.isAnonymous) {
      try {
        final result = await currentAuthUser.linkWithCredential(credential);
        final user = result.user;
        if (user == null) throw StateError('Googleアカウントの連携に失敗しました');
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') rethrow;
        // 既に別ユーザーに紐づくGoogleアカウントの場合は通常サインインへ
      }
    }

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) throw StateError('Googleサインインに失敗しました');
    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
