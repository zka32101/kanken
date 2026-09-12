import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/friend_list_screen.dart';
import '../views/index.dart';

/// アプリケーションのルーティング定義
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // デイリーチャレンジ画面
        GoRoute(
          path: 'daily-challenge',
          name: 'dailyChallenge',
          builder: (context, state) => const DailyChallengeScreen(),
        ),

        // 学習進捗ダッシュボード
        GoRoute(
          path: 'progress',
          name: 'progress',
          builder: (context, state) => const ProgressDashboardScreen(),
        ),

        // ランキング
        GoRoute(
          path: 'ranking',
          name: 'ranking',
          builder: (context, state) => const RankingScreen(),
        ),

        // フレンドリスト
        GoRoute(
          path: 'friends',
          name: 'friends',
          builder: (context, state) => const FriendListScreen(),
        ),

        // コレクションバッジ
        GoRoute(
          path: 'collection-badge',
          name: 'collectionBadge',
          builder: (context, state) => const CollectionBadgeScreen(),
        ),

        // 弱点漢字モード
        GoRoute(
          path: 'weak-kanji',
          name: 'weakKanji',
          builder: (context, state) => const WeakKanjiModeScreen(),
        ),

        // 手書き練習
        GoRoute(
          path: 'handwriting',
          name: 'handwriting',
          builder: (context, state) => const HandwritingPracticeScreen(),
        ),

        // 模擬試験
        GoRoute(
          path: 'mock-exam',
          name: 'mockExam',
          builder: (context, state) => const MockExamScreen(),
        ),

        // 保護者ダッシュボード
        GoRoute(
          path: 'parent-dashboard',
          name: 'parentDashboard',
          builder: (context, state) => const ParentDashboardScreen(),
        ),
      ],
    ),
  ],

  // エラーハンドリング
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('エラー')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ページが見つかりません'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    ),
  ),
);

/// ナビゲーション ヘルパー
extension NavigationExtension on BuildContext {
  /// ホームに戻る
  void goHome() => go('/');

  /// デイリーチャレンジに遷移
  void goDailyChallenge() => push('/daily-challenge');

  /// 学習進捗に遷移
  void goProgress() => push('/progress');

  /// ランキングに遷移
  void goRanking() => push('/ranking');

  /// フレンドリストに遷移
  void goFriends() => push('/friends');

  /// コレクションバッジに遷移
  void goCollectionBadge() => push('/collection-badge');

  /// 弱点漢字に遷移
  void goWeakKanji() => push('/weak-kanji');

  /// 手書き練習に遷移
  void goHandwriting() => push('/handwriting');

  /// 模擬試験に遷移
  void goMockExam() => push('/mock-exam');

  /// 保護者ダッシュボードに遷移
  void goParentDashboard() => push('/parent-dashboard');
}
