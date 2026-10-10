import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/multiplayer.dart';

BattleParticipant _p(String uid) => BattleParticipant(
      userId: uid,
      displayName: uid,
      avatarUrl: null,
      currentScore: 0,
      correctAnswers: 0,
      level: 10,
      joinedAt: DateTime(2026, 10, 10),
      isReady: true,
      isFinished: false,
    );

BattleRoom _room(List<BattleParticipant> ps) => BattleRoom(
      roomId: 'r1',
      creatorId: 'A',
      roomName: 'room',
      examLevel: 10,
      maxParticipants: 4,
      participants: ps,
      status: 'waiting',
      totalQuestions: 10,
      timePerQuestionSeconds: 30,
      createdAt: DateTime(2026, 10, 10),
    );

void main() {
  test('participantIds は participants の uid を順に並べたもの', () {
    final r = _room([_p('A'), _p('B'), _p('C')]);
    expect(r.participantIds, ['A', 'B', 'C']);
  });

  test('toJson に participantIds が入る（セキュリティルールの参加判定用）', () {
    final json = _room([_p('A'), _p('B')]).toJson();
    expect(json['participantIds'], ['A', 'B']);
    expect((json['participants'] as List).length, 2);
  });

  test('参加者を足すと participantIds も増える（参加時の更新と同じ組み立て）', () {
    final before = _room([_p('A')]);
    final after = _room([...before.participants, _p('B')]);
    expect(before.toJson()['participantIds'], ['A']);
    expect(after.toJson()['participantIds'], ['A', 'B']);
  });
}
