import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/challenge_invitation.dart';

void main() {
  group('ChallengeInvitation Model Tests', () {
    // Test 1: モデル生成
    test('Create ChallengeInvitation with pending status', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final challenge = ChallengeInvitation(
        invitationId: 'inv-001',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
      );

      expect(challenge.invitationId, 'inv-001');
      expect(challenge.status, ChallengeStatus.pending);
      expect(challenge.fromUserName, 'Alice');
      expect(challenge.toUserName, 'Bob');
    });

    // Test 2: JSON デシリアライズ - 基本フィールド
    test('Deserialize ChallengeInvitation from JSON', () {
      final json = {
        'invitationId': 'inv-002',
        'fromUserId': 'user1',
        'fromUserName': 'Alice',
        'toUserId': 'user2',
        'toUserName': 'Bob',
        'status': 'pending',
        'createdAt': null,
        'expiresAt': null,
      };

      final challenge = ChallengeInvitation.fromJson(json);

      expect(challenge.invitationId, 'inv-002');
      expect(challenge.fromUserName, 'Alice');
      expect(challenge.status, ChallengeStatus.pending);
    });

    // Test 3: JSON シリアライズ
    test('Serialize ChallengeInvitation to JSON', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final challenge = ChallengeInvitation(
        invitationId: 'inv-003',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final json = challenge.toJson();

      expect(json['invitationId'], 'inv-003');
      expect(json['status'], 'pending');
      expect(json['fromUserName'], 'Alice');
    });

    // Test 4: ステータスラベル - pending
    test('Get status label for pending challenge', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-004',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getStatusLabel(), '待機中');
    });

    // Test 5: ステータスラベル - accepted
    test('Get status label for accepted challenge', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-005',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.accepted,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getStatusLabel(), 'チャレンジ中');
    });

    // Test 6: ステータスラベル - completed
    test('Get status label for completed challenge', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-006',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getStatusLabel(), '完了');
    });

    // Test 7: ステータスラベル - declined
    test('Get status label for declined challenge', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-007',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.declined,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getStatusLabel(), '拒否');
    });

    // Test 8: 勝者判定 - fromUser が勝利
    test('Determine winner when fromScore > toScore', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-008',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 85,
        toScore: 70,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getWinner(), 'user1');
    });

    // Test 9: 勝者判定 - toUser が勝利
    test('Determine winner when toScore > fromScore', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-009',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 60,
        toScore: 90,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getWinner(), 'user2');
    });

    // Test 10: 勝者判定 - 同点
    test('No winner when scores are equal (tie)', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-010',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 80,
        toScore: 80,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getWinner(), null);
    });

    // Test 11: 勝者判定 - スコアなし
    test('No winner when scores are null', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-011',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getWinner(), null);
    });

    // Test 12: スコア差計算
    test('Calculate score difference correctly', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-012',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 95,
        toScore: 70,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getScoreDifference(), 25);
    });

    // Test 13: スコア差計算 - 逆順
    test('Calculate score difference with reversed scores', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-013',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 50,
        toScore: 100,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getScoreDifference(), 50);
    });

    // Test 14: スコア差計算 - スコアなし
    test('Score difference is null when scores are missing', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-014',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.getScoreDifference(), null);
    });

    // Test 15: 有効期限切れ判定 - 有効
    test('Challenge is not expired when within valid period', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-015',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );

      expect(challenge.isExpired, false);
    });

    // Test 16: 有効期限切れ判定 - 期限切れ
    test('Challenge is expired when past expiration date', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-016',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(challenge.isExpired, true);
    });

    // Test 17: JSON ラウンドトリップ - スコア付き
    test('JSON round-trip with scores preserves all data', () {
      final original = ChallengeInvitation(
        invitationId: 'inv-017',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.completed,
        fromScore: 88,
        toScore: 75,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final json = original.toJson();
      final restored = ChallengeInvitation.fromJson(json);

      expect(restored.invitationId, original.invitationId);
      expect(restored.fromScore, original.fromScore);
      expect(restored.toScore, original.toScore);
      expect(restored.status, original.status);
    });

    // Test 18: ステータス遷移 - pending → accepted
    test('Status can transition from pending to accepted', () {
      var challenge = ChallengeInvitation(
        invitationId: 'inv-018',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.status, ChallengeStatus.pending);

      // ステータスを新しいオブジェクトで変更（実装時は update メソッドで行う）
      challenge = ChallengeInvitation(
        invitationId: challenge.invitationId,
        fromUserId: challenge.fromUserId,
        fromUserName: challenge.fromUserName,
        toUserId: challenge.toUserId,
        toUserName: challenge.toUserName,
        status: ChallengeStatus.accepted,
        fromScore: challenge.fromScore,
        toScore: challenge.toScore,
        createdAt: challenge.createdAt,
        completedAt: challenge.completedAt,
        expiresAt: challenge.expiresAt,
      );

      expect(challenge.status, ChallengeStatus.accepted);
    });

    // Test 19: ステータス遷移 - accepted → completed
    test('Status can transition from accepted to completed', () {
      var challenge = ChallengeInvitation(
        invitationId: 'inv-019',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.accepted,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.status, ChallengeStatus.accepted);

      challenge = ChallengeInvitation(
        invitationId: challenge.invitationId,
        fromUserId: challenge.fromUserId,
        fromUserName: challenge.fromUserName,
        toUserId: challenge.toUserId,
        toUserName: challenge.toUserName,
        status: ChallengeStatus.completed,
        fromScore: 85,
        toScore: 70,
        createdAt: challenge.createdAt,
        completedAt: DateTime.now(),
        expiresAt: challenge.expiresAt,
      );

      expect(challenge.status, ChallengeStatus.completed);
      expect(challenge.fromScore, 85);
      expect(challenge.toScore, 70);
    });

    // Test 20: toString メソッド
    test('toString returns formatted challenge info', () {
      final challenge = ChallengeInvitation(
        invitationId: 'inv-020',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        toUserName: 'Bob',
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final str = challenge.toString();
      expect(str, contains('Alice'));
      expect(str, contains('Bob'));
      expect(str, contains('pending'));
    });
  });
}
