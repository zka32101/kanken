import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/friend_challenge.dart';

FriendChallenge _make({
  String id = 'ch-001',
  ChallengeStatus status = ChallengeStatus.pending,
  int? challengerScore,
  int? challengeeScore,
  DateTime? createdAt,
  DateTime? acceptedAt,
  DateTime? dueAt,
}) {
  return FriendChallenge(
    challengeId: id,
    challengerUserId: 'user1',
    challengerName: 'Alice',
    challengeeUserId: 'user2',
    changetesName: 'Bob',
    status: status,
    targetScore: 80,
    description: '80点以上を目指そう',
    createdAt: createdAt ?? DateTime.now(),
    acceptedAt: acceptedAt,
    dueAt: dueAt ?? DateTime.now().add(const Duration(days: 7)),
    challengerScore: challengerScore,
    challengeeScore: challengeeScore,
  );
}

void main() {
  group('FriendChallenge Model Tests', () {
    // Test 1: モデル生成
    test('Create FriendChallenge with pending status', () {
      final challenge = _make(id: 'ch-001');

      expect(challenge.challengeId, 'ch-001');
      expect(challenge.status, ChallengeStatus.pending);
      expect(challenge.challengerName, 'Alice');
      expect(challenge.changetesName, 'Bob');
      expect(challenge.targetScore, 80);
    });

    // Test 2: プロフィールIDの既定値
    test('Profile IDs default to "default"', () {
      final challenge = _make();

      expect(challenge.challengerProfileId, 'default');
      expect(challenge.challengeeProfileId, 'default');
    });

    // Test 3: JSON デシリアライズ - 欠損フィールドはデフォルト値
    test('Deserialize FriendChallenge from JSON with defaults', () {
      final challenge = FriendChallenge.fromJson({
        'challengeId': 'ch-002',
        'challengerUserId': 'user1',
        'challengerName': 'Alice',
        'challengeeUserId': 'user2',
        'status': 'pending',
      });

      expect(challenge.challengeId, 'ch-002');
      expect(challenge.challengerName, 'Alice');
      expect(challenge.status, ChallengeStatus.pending);
      expect(challenge.challengerProfileId, 'default');
      expect(challenge.acceptedAt, null);
      expect(challenge.challengerScore, null);
      // dueAt 未指定なら生成時点から7日後
      expect(challenge.isExpired, false);
    });

    // Test 4: JSON シリアライズ
    test('Serialize FriendChallenge to JSON', () {
      final json = _make(id: 'ch-003').toJson();

      expect(json['challengeId'], 'ch-003');
      expect(json['status'], 'pending');
      expect(json['challengerName'], 'Alice');
      expect(json['targetScore'], 80);
    });

    // Test 5-8: ステータス文字列のラウンドトリップ
    for (final s in ChallengeStatus.values) {
      test('JSON round-trip preserves status ${s.name}', () {
        final json = _make(status: s).toJson();

        expect(json['status'], s.name);
        expect(FriendChallenge.fromJson(json).status, s);
      });
    }

    // Test 9: 不明なステータスは pending 扱い
    test('Unknown status falls back to pending', () {
      final challenge = FriendChallenge.fromJson({'status': 'unknown'});

      expect(challenge.status, ChallengeStatus.pending);
    });

    // Test 10: 勝者判定 - challenger が勝利
    test('Determine winner when challenger score is higher', () {
      final challenge = _make(
        status: ChallengeStatus.completed,
        challengerScore: 85,
        challengeeScore: 70,
      );

      expect(challenge.getWinner(), 'user1');
    });

    // Test 11: 勝者判定 - challengee が勝利
    test('Determine winner when challengee score is higher', () {
      final challenge = _make(
        status: ChallengeStatus.completed,
        challengerScore: 60,
        challengeeScore: 90,
      );

      expect(challenge.getWinner(), 'user2');
    });

    // Test 12: 勝者判定 - 同点
    test('No winner when scores are equal (tie)', () {
      final challenge = _make(
        status: ChallengeStatus.completed,
        challengerScore: 80,
        challengeeScore: 80,
      );

      expect(challenge.getWinner(), null);
    });

    // Test 13: 勝者判定 - スコアなし / 片方のみ
    test('No winner when scores are missing', () {
      expect(_make().getWinner(), null);
      expect(_make(challengerScore: 90).getWinner(), null);
      expect(_make(challengeeScore: 90).getWinner(), null);
    });

    // Test 14: 有効期限切れ判定 - 有効
    test('Challenge is not expired when within valid period', () {
      final challenge = _make(
        dueAt: DateTime.now().add(const Duration(days: 5)),
      );

      expect(challenge.isExpired, false);
    });

    // Test 15: 有効期限切れ判定 - 期限切れ
    test('Challenge is expired when past due date', () {
      final challenge = _make(
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        dueAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(challenge.isExpired, true);
    });

    // Test 16: 終了判定（completed / declined のみ終了）
    test('isFinished is true only for completed or declined', () {
      expect(_make(status: ChallengeStatus.pending).isFinished, false);
      expect(_make(status: ChallengeStatus.accepted).isFinished, false);
      expect(_make(status: ChallengeStatus.completed).isFinished, true);
      expect(_make(status: ChallengeStatus.declined).isFinished, true);
    });

    // Test 17: JSON ラウンドトリップ - スコア付き
    test('JSON round-trip with scores preserves all data', () {
      final original = _make(
        id: 'ch-017',
        status: ChallengeStatus.completed,
        challengerScore: 88,
        challengeeScore: 75,
        createdAt: DateTime(2026, 9, 1),
        acceptedAt: DateTime(2026, 9, 2),
        dueAt: DateTime(2026, 9, 8),
      );

      final restored = FriendChallenge.fromJson(original.toJson());

      expect(restored.challengeId, original.challengeId);
      expect(restored.challengerScore, 88);
      expect(restored.challengeeScore, 75);
      expect(restored.status, ChallengeStatus.completed);
      expect(restored.createdAt, original.createdAt);
      expect(restored.acceptedAt, original.acceptedAt);
      expect(restored.dueAt, original.dueAt);
    });
  });
}
