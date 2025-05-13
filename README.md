# AnimalGestioneProject

## プライバシーポリシーURLとサポートURL

Appleのアプリリリース用プライバシーポリシーURLとサポートURLとして、以下のGitHub PagesのURLを使用してください：

### プライバシーポリシーURL

```
https://[あなたのGitHubユーザー名].github.io/AnimalGestioneProject/
```

### サポートURL

```
https://[あなたのGitHubユーザー名].github.io/AnimalGestioneProject/support.html
```

例えば、GitHubユーザー名が `shingo-sasaki-10` の場合：

### プライバシーポリシーURL

```
https://shingo-sasaki-10.github.io/AnimalGestioneProject/
```

### サポートURL

```
https://shingo-sasaki-10.github.io/AnimalGestioneProject/support.html
```

## セットアップ方法

1. リポジトリの Settings > Pages で、以下の設定を行ってください：
   - Source: Deploy from a branch
   - Branch: main
   - Folder: /docs

2. 設定後、GitHub Pagesのサイトが公開されるまで数分待ちます。

3. 公開されたURLをAppleのアプリリリースフォームのプライバシーポリシーURL欄に入力してください。

## ファイル構成

- `/docs/index.html` - プライバシーポリシーのHTML版
- `/docs/privacy-policy.md` - プライバシーポリシーのMarkdown版
- `/docs/support.html` - サポートページのHTML版
- `/docs/support.md` - サポートページのMarkdown版
- `/AnimalGestioneProject/Views/PrivacyPolicyView.swift` - アプリ内に表示されるプライバシーポリシー
- `/AnimalGestioneProject/Views/PrivacyPolicyURLView.swift` - プライバシーポリシーURL表示ビュー
- `/AnimalGestioneProject/Views/SupportURLView.swift` - サポートURL表示ビュー
- `/AnimalGestioneProject/Config/URLProvider.swift` - URL管理クラス

## 設定変更方法

アプリ公開前に、以下の手順でGitHubユーザー名を設定してください：

1. `URLProvider.swift` ファイルを開き、`privacyPolicyURL`、`supportURL`、`gitHubRepoURL` のURLを実際のGitHubアカウント名に合わせて変更します：
   ```swift
   public static let privacyPolicyURL = "https://shingo-sasaki-10.github.io/AnimalGestioneProject/"
   public static let supportURL = "https://shingo-sasaki-10.github.io/AnimalGestioneProject/support.html"
   public static let gitHubRepoURL = "https://github.com/shingo-sasaki-10/AnimalGestioneProject"
   ```

2. `PrivacyPolicyURLView.swift` と `SupportURLView.swift` が正しく表示されることを確認します。

## 注意事項

- プライバシーポリシーの内容を更新する場合は、アプリ内の表示（`PrivacyPolicyView.swift`）と、このリポジトリの両方を更新してください。
- サポートページの内容を更新する場合も、アプリ内の表示とGitHub Pagesの両方を更新してください。
- Appleのアプリリリースフォームでは、プライバシーポリシーURLとサポートURLの両方を提出する必要があります。
