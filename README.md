# AnimalGestioneProject

## プライバシーポリシーURL

Appleのアプリリリース用プライバシーポリシーURLとして、以下のGitHub PagesのURLを使用してください：

```
https://[あなたのGitHubユーザー名].github.io/AnimalGestioneProject/
```

例えば、GitHubユーザー名が `shingo-sasaki-10` の場合：

```
https://shingo-sasaki-10.github.io/AnimalGestioneProject/
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
- `/AnimalGestioneProject/Views/PrivacyPolicyView.swift` - アプリ内に表示されるプライバシーポリシー
- `/AnimalGestioneProject/Config/URLProvider.swift` - プライバシーポリシーURLを管理するクラス

## 設定変更方法

アプリ公開前に、以下の手順でGitHubユーザー名を設定してください：

1. `URLProvider.swift` ファイルを開き、`privacyPolicyURL` と `gitHubRepoURL` のURLを実際のGitHubアカウント名に合わせて変更します：
   ```swift
   public static let privacyPolicyURL = "https://shingo-sasaki-10.github.io/AnimalGestioneProject/"
   public static let gitHubRepoURL = "https://github.com/shingo-sasaki-10/AnimalGestioneProject"
   ```

2. `PrivacyPolicyURLView.swift` が正しく表示されることを確認します。

## 注意事項

- プライバシーポリシーの内容を更新する場合は、アプリ内の表示（`PrivacyPolicyView.swift`）と、このリポジトリの両方を更新してください。
