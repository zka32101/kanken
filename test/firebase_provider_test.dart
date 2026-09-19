import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kanken/providers/firebase_provider.dart';

// Firebase Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-123';
}

void main() {
  group('Firebase Provider Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
    });

    test('firebaseProvider returns FirebaseFirestore instance', () {
      final container = ProviderContainer();
      final firestore = container.read(firebaseProvider);

      expect(firestore, isA<FirebaseFirestore>());
    });

    test('firebaseAuthProvider returns FirebaseAuth instance', () {
      final container = ProviderContainer();
      final auth = container.read(firebaseAuthProvider);

      expect(auth, isA<FirebaseAuth>());
    });

    test('currentUserIdProvider returns null when not authenticated', () {
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );

      when(() => mockAuth.currentUser).thenReturn(null);

      final userId = container.read(currentUserIdProvider);

      expect(userId, isNull);
    });

    test('currentUserIdProvider returns UID when authenticated', () {
      final mockUser = MockUser();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );

      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final userId = container.read(currentUserIdProvider);

      expect(userId, equals('test-user-123'));
    });

    test('currentUserProvider watches auth state changes', () async {
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );

      final mockStream = Stream<User?>.value(null);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => mockStream);

      final userStream = container.read(currentUserProvider.stream);

      expect(userStream, emits(null));
    });
  });
}
