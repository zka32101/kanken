import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/parent_dashboard.dart';

part 'parent_dashboard_provider.g.dart';

/// 保護者がリンクしている子どもの一覧を取得
@riverpod
Future<List<ChildLearningStats>> linkedChildren(LinkedChildrenRef ref) async {
  final parentId = FirebaseAuth.instance.currentUser?.uid;
  if (parentId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('parentLinks')
      .where('parentId', isEqualTo: parentId)
      .get();

  final childrenStats = <ChildLearningStats>[];

  for (var doc in snapshot.docs) {
    final childId = doc['childId'] as String;

    try {
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .get();

      if (childDoc.exists) {
        final data = childDoc.data() ?? {};
        childrenStats.add(ChildLearningStats(
          childId: childId,
          childName: data['displayName'] as String? ?? 'Unknown',
          currentLevel: data['currentLevel'] as int? ?? 10,
          totalQuestions: data['totalQuestions'] as int? ?? 0,
          correctAnswers: data['correctAnswers'] as int? ?? 0,
          accuracyRate: (data['accuracyRate'] as num?)?.toDouble() ?? 0,
          streakDays: data['streakCount'] as int? ?? 0,
          longestStreak: data['longestStreak'] as int? ?? 0,
          totalLearningMinutes: data['totalLearningMinutes'] as int? ?? 0,
          lastLearningAt: data['lastLearningAt'] is Timestamp
              ? (data['lastLearningAt'] as Timestamp).toDate()
              : DateTime.now(),
          badgesAcquired: data['badgesAcquired'] as int? ?? 0,
          totalBadges: data['totalBadges'] as int? ?? 0,
        ));
      }
    } catch (e) {
      // 子どものデータ取得に失敗した場合はスキップ
      continue;
    }
  }

  return childrenStats;
}

/// 子どもの学習グラフデータを取得（過去30日間）
@riverpod
Future<List<LearningDataPoint>> childLearningGraph(
  ChildLearningGraphRef ref,
  String childId,
) async {
  final startDate = DateTime.now().subtract(const Duration(days: 30));

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(childId)
      .collection('learningHistory')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .orderBy('date')
      .get();

  return snapshot.docs
      .map((doc) => LearningDataPoint.fromJson(doc.data()))
      .toList();
}

/// 子どもの弱点分野を取得
@riverpod
Future<List<ChildWeakArea>> childWeakAreas(
  ChildWeakAreasRef ref,
  String childId,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(childId)
      .collection('weakAreas')
      .orderBy('accuracyRate')
      .get();

  return snapshot.docs
      .map((doc) => ChildWeakArea.fromJson(doc.data()))
      .toList();
}

/// 保護者ダッシュボード State
class ParentDashboardState {
  final bool isLoading;
  final String? error;
  final String? selectedChildId;

  ParentDashboardState({
    this.isLoading = false,
    this.error,
    this.selectedChildId,
  });

  ParentDashboardState copyWith({
    bool? isLoading,
    String? error,
    String? selectedChildId,
  }) {
    return ParentDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedChildId: selectedChildId ?? this.selectedChildId,
    );
  }
}

/// 保護者ダッシュボード Notifier
class ParentDashboardNotifier extends StateNotifier<ParentDashboardState> {
  ParentDashboardNotifier() : super(ParentDashboardState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 子どもをリンク
  Future<void> linkChild({
    required String childEmail,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final parentId = _auth.currentUser?.uid;
      if (parentId == null) throw Exception('保護者がログインしていません');

      // 子どものメールアドレスからユーザーIDを検索
      final childSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: childEmail)
          .limit(1)
          .get();

      if (childSnapshot.docs.isEmpty) {
        throw Exception('このメールアドレスのユーザーが見つかりません');
      }

      final childId = childSnapshot.docs[0].id;

      // parentLinksコレクションにリンクを追加
      await _firestore.collection('parentLinks').add({
        'parentId': parentId,
        'childId': childId,
        'linkedAt': Timestamp.now(),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'リンク失敗: $e',
      );
    }
  }

  /// 子どものリンクを解除
  Future<void> unlinkChild({
    required String childId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final parentId = _auth.currentUser?.uid;
      if (parentId == null) throw Exception('保護者がログインしていません');

      // parentLinksコレクションからリンクを削除
      final snapshot = await _firestore
          .collection('parentLinks')
          .where('parentId', isEqualTo: parentId)
          .where('childId', isEqualTo: childId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'リンク解除失敗: $e',
      );
    }
  }

  /// 選択した子どもを切り替え
  void selectChild(String? childId) {
    state = state.copyWith(selectedChildId: childId);
  }
}

/// 保護者ダッシュボード Notifier Provider
@riverpod
StateNotifier<ParentDashboardState> parentDashboardNotifier(
  ParentDashboardNotifierRef ref,
) {
  return ParentDashboardNotifier();
}
