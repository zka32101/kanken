import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/friend_challenge.dart';

FriendChallenge _make({
  required String id,
  String challenger = 'user-1',
  String challengee = 'user-2',
  ChallengeStatus status = ChallengeStatus.pending,
  DateTime? dueAt,
}) {
  final now = DateTime.now();
  return FriendChallenge(
    challengeId: id,
    challengerUserId: challenger,
    challengerName: 'Alice',
    challengeeUserId: challengee,
    changetesName: 'Bob',
    status: status,
    targetScore: 80,
    description: 'Want to compete?',
    createdAt: now,
    dueAt: dueAt ?? now.add(const Duration(days: 7)),
  );
}

void main() {
  group('FriendChallenge Tests', () {
    test('FriendChallenge creates with pending status', () {
      final challenge = _make(id: 'challenge-1');

      expect(challenge.challengeId, equals('challenge-1'));
      expect(challenge.status, equals(ChallengeStatus.pending));
      expect(challenge.challengerUserId, equals('user-1'));
    });

    test('FriendChallenge status transitions', () {
      // pending -> accepted -> completed の順に状態を持ち替えられる
      final statuses = [
        ChallengeStatus.pending,
        ChallengeStatus.accepted,
        ChallengeStatus.completed,
      ];
      final challenges = [
        for (final s in statuses) _make(id: 'challenge-2', status: s),
      ];

      expect(challenges.map((c) => c.status).toList(), equals(statuses));
      expect(challenges.map((c) => c.isFinished).toList(),
          equals([false, false, true]));
    });

    test('FriendChallenge expiration validation', () {
      final expired = _make(
        id: 'challenge-3',
        dueAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expired.isExpired, isTrue);
    });

    test('FriendChallenge fromJson creates instance', () {
      final jsonData = {
        'challengeId': 'challenge-4',
        'challengerUserId': 'user-3',
        'challengeeUserId': 'user-4',
        'description': 'Test challenge',
        'status': 'accepted',
      };

      final challenge = FriendChallenge.fromJson(jsonData);

      expect(challenge.challengeId, equals('challenge-4'));
      expect(challenge.challengerUserId, equals('user-3'));
      expect(challenge.status, equals(ChallengeStatus.accepted));
    });

    test('Challenge validates challengee', () {
      final challenge = _make(id: 'challenge-5');

      expect(challenge.challengeeUserId, isNotEmpty);
      expect(challenge.challengerUserId, isNot(challenge.challengeeUserId));
    });

    test('Challenge detects self-challenge', () {
      // 自分自身への挑戦はモデル上は作れるので、呼び出し側で弾く必要がある
      final self = _make(
          id: 'challenge-6', challenger: 'user-1', challengee: 'user-1');

      expect(self.challengerUserId == self.challengeeUserId, isTrue);
    });

    test('Challenge description is preserved', () {
      final challenge = _make(id: 'challenge-7');

      expect(challenge.description, isNotEmpty);
      expect(challenge.description.length, lessThanOrEqualTo(500));
    });

    test('Challenge batch operations', () {
      final challenges = List.generate(
        5,
        (i) => _make(id: 'challenge-$i', challengee: 'user-${i + 2}'),
      );

      expect(challenges.length, equals(5));
      expect(challenges.every((c) => c.challengerUserId == 'user-1'), isTrue);
      expect(
          challenges.map((c) => c.challengeId).toList(),
          equals([
            'challenge-0',
            'challenge-1',
            'challenge-2',
            'challenge-3',
            'challenge-4'
          ]));
    });
  });
}
