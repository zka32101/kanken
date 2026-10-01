# 効果音ファイル配置について

`lib/services/sound_effect_service.dart` が参照する以下の音声ファイルをこのフォルダに配置してください。
ファイルが存在しない間は再生時に例外が発生しますが、`_playSoundFile` 内で catch しているため
アプリ本体はクラッシュしません（単に無音になります）。

- `correct.mp3` — 正解時のSE
- `incorrect.mp3` — 不正解時のSE
- `badge_unlocked.mp3` — バッジ獲得時のSE
- `combo.mp3` — コンボ達成時のSE

形式は mp3 を想定（`AssetSource` 経由で再生、`pubspec.yaml` の `assets/sounds/` として登録済み）。
