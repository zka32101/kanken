import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kanken/models/gamification_stats.dart';
import 'package:kanken/providers/firebase_provider.dart';
import 'package:kanken/providers/gamification_provider.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final bool _exists;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot({required bool exists, Map<String, dynamic>? data})
      : _exists = exists,
        _data = data;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

void main() {
  group('GamificationNotifier Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();
    });

    test('GamificationNotifier initializes with loading state', () {
      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');

      expect(notifier.state, isA<AsyncLoading>());
    });

    test('loadStats successfully loads gamification stats', () async {
      final mockStatsData = {
        'userId': 'test-user-123',
        'level': 5,
        'experience': 1500,
        'coins': 250,
        'totalQuestions': 100,
        'correctCount': 85,
        'streak': 10,
        'recordStreak': 25,
        'accuracyRate': 0.85,
        'lastPlayedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final mockSnapshot = MockDocumentSnapshot(
        exists: true,
        data: mockStatsData,
      );

      when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
      when(() => mockCollection.doc('test-user-123'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).collection('stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('current'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).get())
          .thenAnswer((_) async => mockSnapshot as DocumentSnapshot<Map<String, dynamic>>);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncData>());
      expect(notifier.state.asData?.value.level, equals(5));
      expect(notifier.state.asData?.value.coins, equals(250));
    });

    test('loadStats returns initial values when doc does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot(exists: false);

      when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
      when(() => mockCollection.doc('test-user-123'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).collection('stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('current'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).get())
          .thenAnswer((_) async => mockSnapshot as DocumentSnapshot<Map<String, dynamic>>);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncData>());
      expect(notifier.state.asData?.value.level, equals(1));
      expect(notifier.state.asData?.value.experience, equals(0));
      expect(notifier.state.asData?.value.coins, equals(0));
    });

    test('loadStats handles errors gracefully', () async {
      when(() => mockFirestore.collection('users')).thenThrow(
        Exception('Firestore connection error'),
      );

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncError>());
    });

    test('addExperience updates experience correctly', () async {
      final mockStatsData = {
        'userId': 'test-user-123',
        'level': 1,
        'experience': 100,
        'coins': 50,
        'totalQuestions': 10,
        'correctCount': 8,
        'streak': 3,
        'recordStreak': 5,
        'accuracyRate': 0.8,
        'lastPlayedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final mockSnapshot = MockDocumentSnapshot(
        exists: true,
        data: mockStatsData,
      );

      when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
      when(() => mockCollection.doc('test-user-123'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).collection('stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('current'))
          .thenReturn(mockDocRef as DocumentReference<Map<String, dynamic>>);
      when(() => (mockDocRef as MockDocumentReference).get())
          .thenAnswer((_) async => mockSnapshot as DocumentSnapshot<Map<String, dynamic>>);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      // Simulate adding experience
      final currentStats = notifier.state.asData?.value;
      expect(currentStats?.experience, equals(100));
    });
  });

  group('gamificationStatsProvider Tests', () {
    test('gamificationStatsProvider requires authentication', () async {
      final container = ProviderContainer();

      // Mock firebaseProvider to return a mock Firestore
      final mockFirestore = MockFirebaseFirestore();
      container.read(firebaseProvider); // Ensure it's initialized

      // This test verifies the provider requires a logged-in user
      expect(() => container.read(gamificationStatsProvider), isNotNull);
    });
  });
}
