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



# ディレクトリの存在を確認
mkdir -p /Users/shingo/Xcode_Local/git/AnimalGestioneProject/Pods/Target\ Support\ Files/Pods-AnimalGestioneProject/

# 新しいスクリプトを作成
cat > "/Users/shingo/Xcode_Local/git/AnimalGestioneProject/Pods/Target Support Files/Pods-AnimalGestioneProject/Pods-AnimalGestioneProject-resources.sh" << 'EOL'
#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath -q "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR

if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then
  # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
  # resources to, so exit 0 (signaling success).
  exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

# Copy GoogleMobileAdsResources.bundle
if [ -d "${PODS_ROOT}/GoogleMobileAds/Resources/GoogleMobileAdsResources.bundle" ]; then
  mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  cp -r "${PODS_ROOT}/GoogleMobileAds/Resources/GoogleMobileAdsResources.bundle" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi

# Copy UserMessagingPlatformResources.bundle
if [ -d "${PODS_ROOT}/GoogleUserMessagingPlatform/Resources/UserMessagingPlatformResources.bundle" ]; then
  mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  cp -r "${PODS_ROOT}/GoogleUserMessagingPlatform/Resources/UserMessagingPlatformResources.bundle" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi

# Find bundles using find command
find "${PODS_ROOT}" -name "GoogleMobileAdsResources.bundle" -type d | while read -r BUNDLE; do
  echo "Copying GoogleMobileAdsResources bundle: ${BUNDLE}"
  mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  cp -r "${BUNDLE}" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
done

find "${PODS_ROOT}" -name "UserMessagingPlatformResources.bundle" -type d | while read -r BUNDLE; do
  echo "Copying UserMessagingPlatform bundle: ${BUNDLE}"
  mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  cp -r "${BUNDLE}" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
done

rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "${XCASSET_FILES:-}" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  if [ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]; then
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  else
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${TARGET_TEMP_DIR}/assetcatalog_generated_info.plist"
  fi
fi
EOL

# スクリプトに実行権限を付与
chmod 755 "/Users/shingo/Xcode_Local/git/AnimalGestioneProject/Pods/Target Support Files/Pods-AnimalGestioneProject/Pods-AnimalGestioneProject-resources.sh"