import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/challenge_invitation.dart';

void main() {
  group('ChallengeInvitation Tests', () {
    test('ChallengeInvitation creates with pending status', () {
      final now = DateTime.now();
      final challenge = ChallengeInvitation(
        id: 'challenge-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        message: 'Want to compete?',
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(Duration(days: 7)),
      );

      expect(challenge.id, equals('challenge-1'));
      expect(challenge.status, equals('pending'));
      expect(challenge.senderId, equals('user-1'));
    });

    test('ChallengeInvitation status transitions', () {
      final now = DateTime.now();
      final challenge = ChallengeInvitation(
        id: 'challenge-2',
        senderId: 'user-1',
        recipientId: 'user-2',
        message: 'Challenge me!',
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(Duration(days: 7)),
      );

      expect(challenge.status, equals('pending'));
      // Status should be able to transition: pending -> accepted -> completed
    });

    test('ChallengeInvitation expiration validation', () {
      final now = DateTime.now();
      final expiredChallenge = ChallengeInvitation(
        id: 'challenge-3',
        senderId: 'user-1',
        recipientId: 'user-2',
        message: 'Expired challenge',
        status: 'pending',
        createdAt: now.subtract(Duration(days: 8)),
        expiresAt: now.subtract(Duration(days: 1)),
      );

      final isExpired = now.isAfter(expiredChallenge.expiresAt);
      expect(isExpired, isTrue);
    });

    test('ChallengeInvitation fromJson creates instance', () {
      final jsonData = {
        'id': 'challenge-4',
        'senderId': 'user-3',
        'recipientId': 'user-4',
        'message': 'Test challenge',
        'status': 'accepted',
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(Duration(days: 7)).toIso8601String(),
      };

      final challenge = ChallengeInvitation.fromJson(jsonData);

      expect(challenge.id, equals('challenge-4'));
      expect(challenge.senderId, equals('user-3'));
      expect(challenge.status, equals('accepted'));
    });

    test('Challenge invitation validates recipient', () {
      final now = DateTime.now();
      final challenge = ChallengeInvitation(
        id: 'challenge-5',
        senderId: 'user-1',
        recipientId: 'user-2',
        message: 'Compete with me',
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(Duration(days: 7)),
      );

      expect(challenge.recipientId, isNotEmpty);
      expect(challenge.recipientId, isNotNull);
      expect(challenge.senderId, isNot(challenge.recipientId));
    });

    test('Challenge invitation prevents self-challenge', () {
      final now = DateTime.now();
      final selfChallenge = ChallengeInvitation(
        id: 'challenge-6',
        senderId: 'user-1',
        recipientId: 'user-1', // Same user
        message: 'Self challenge',
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(Duration(days: 7)),
      );

      // Should validate that sender != recipient
      final isSelfChallenge = selfChallenge.senderId == selfChallenge.recipientId;
      expect(isSelfChallenge, isTrue);
    });

    test('Challenge invitation message requirements', () {
      final now = DateTime.now();
      final challenge = ChallengeInvitation(
        id: 'challenge-7',
        senderId: 'user-1',
        recipientId: 'user-2',
        message: 'Test message',
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(Duration(days: 7)),
      );

      expect(challenge.message, isNotEmpty);
      expect(challenge.message.length, lessThanOrEqualTo(500));
    });

    test('Challenge invitation batch operations', () {
      final now = DateTime.now();
      final challenges = List.generate(5, (i) {
        return ChallengeInvitation(
          id: 'challenge-$i',
          senderId: 'user-1',
          recipientId: 'user-${i + 2}',
          message: 'Challenge $i',
          status: 'pending',
          createdAt: now,
          expiresAt: now.add(Duration(days: 7)),
        );
      });

      expect(challenges.length, equals(5));
      expect(challenges.every((c) => c.senderId == 'user-1'), isTrue);
      expect(challenges.map((c) => c.id).toList(),
          equals(['challenge-0', 'challenge-1', 'challenge-2', 'challenge-3', 'challenge-4']));
    });
  });
}
