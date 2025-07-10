# Designer Notes 🎨

デザイナー向けの高機能ノートアプリケーション。Flutter で構築され、shadcn/ui風のモダンなデザインを採用しています。

![Flutter](https://img.shields.io/badge/Flutter-3.32.5-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 特徴

- **shadcn/ui風のモダンデザイン** - クリーンで美しいUI/UX
- **リッチノート機能** - テキスト、画像、カラーパレットをサポート
- **高度な整理機能** - カテゴリ、タグ、お気に入り、ピン留め
- **強力な検索・フィルタリング** - 素早く必要な情報を見つけられる
- **ダークモード対応** - ライト/ダーク/システム設定から選択
- **レスポンシブデザイン** - デスクトップ・タブレット・モバイル対応
- **ローカルストレージ** - データはデバイス内に安全に保存

## 🚀 実装済み機能

### ✅ 完了
- [x] shadcn/ui風のデザインシステム
- [x] Provider による状態管理
- [x] テーマシステム（ライト/ダーク/システム）
- [x] ノート一覧画面（グリッド表示）
- [x] ノートカードコンポーネント
- [x] カテゴリ・タグ管理
- [x] 検索・フィルタリング機能
- [x] お気に入り・ピン留め機能
- [x] ローカルストレージでのデータ永続化
- [x] レスポンシブグリッドレイアウト

### 🚧 開発中
- [ ] ノートエディター画面
- [ ] リッチテキスト編集機能
- [ ] カラーパレット管理
- [ ] 画像挿入・管理機能

### 🗓️ 予定
- [ ] エクスポート機能（Markdown、PDF）
- [ ] インポート機能
- [ ] バックアップ・復元
- [ ] より高度な検索（正規表現対応）
- [ ] ショートカットキー対応
- [ ] プラグインシステム

## 🛠️ 技術スタック

### フロントエンド
- **Flutter 3.32.5** - クロスプラットフォーム開発フレームワーク
- **Dart 3.8.1** - プログラミング言語
- **Provider** - 状態管理
- **SharedPreferences** - ローカルストレージ

### UI/UX
- **Material Design 3** - ベースデザインシステム
- **shadcn/ui風カラーパレット** - モダンで洗練された色使い
- **Flutter Quill** - リッチテキストエディター（予定）
- **レスポンシブデザイン** - 全デバイス対応

### 開発ツール
- **flutter_lints** - コード品質管理
- **json_annotation** - JSON シリアライゼーション
- **build_runner** - コード生成

## 📦 インストール・セットアップ

### 前提条件
- Flutter 3.32.5 以上
- Dart 3.8.1 以上

### インストール手順

1. **リポジトリをクローン**
   ```bash
   git clone https://github.com/w3cdp6084-dev/note.git
   cd designer_notes_app
   ```

2. **依存関係をインストール**
   ```bash
   flutter pub get
   ```

3. **コード生成を実行**
   ```bash
   dart run build_runner build
   ```

4. **アプリを実行**
   ```bash
   # Web
   flutter run -d chrome
   
   # macOS（Xcodeが必要）
   flutter run -d macos
   
   # その他のプラットフォーム
   flutter devices  # 利用可能なデバイスを確認
   flutter run -d [device-id]
   ```

## 🏗️ プロジェクト構造

```
lib/
├── main.dart                 # アプリケーションエントリーポイント
├── models/                   # データモデル
│   ├── note.dart            # ノートモデル
│   └── note.g.dart          # 自動生成されたJSONシリアライゼーション
├── providers/               # 状態管理
│   ├── note_provider.dart   # ノート関連の状態管理
│   └── theme_provider.dart  # テーマ関連の状態管理
├── screens/                 # 画面
│   └── home_screen.dart     # ホーム画面
└── widgets/                 # 再利用可能なコンポーネント
    ├── note_card.dart       # ノートカード
    └── filter_drawer.dart   # フィルタードロワー
```

## 🎨 デザインシステム

### カラーパレット
shadcn/ui風のモダンなカラーシステムを採用：

#### ライトモード
- **Primary**: `#09090B` - メインテキスト・アクション
- **Secondary**: `#F1F5F9` - セカンダリ背景
- **Surface**: `#FFFFFF` - カード・モーダル背景
- **Outline**: `#E2E8F0` - ボーダー・区切り線

#### ダークモード
- **Primary**: `#FAFAFA` - メインテキスト・アクション
- **Secondary**: `#1E293B` - セカンダリ背景
- **Surface**: `#09090B` - カード・モーダル背景
- **Outline**: `#334155` - ボーダー・区切り線

### タイポグラフィ
- **Font Family**: SF Pro Display（システムフォント）
- **Font Weights**: 400（Regular）、500（Medium）、600（Semi-bold）、700（Bold）、800（Extra-bold）

## 🤝 コントリビューション

プルリクエストやイシューの報告を歓迎します！

### 開発の流れ
1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📝 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 🙏 謝辞

- [Flutter](https://flutter.dev/) - 素晴らしいクロスプラットフォーム開発フレームワーク
- [shadcn/ui](https://ui.shadcn.com/) - インスピレーションを与えてくれたデザインシステム
- [Material Design 3](https://m3.material.io/) - ベースとなるデザインシステム

---

**Created with ❤️ for designers**
