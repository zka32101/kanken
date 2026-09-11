import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Firestore インスタンス provider
final firebaseProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Firebase Auth インスタンス provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 現在のユーザー ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

/// 現在のユーザー provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});
