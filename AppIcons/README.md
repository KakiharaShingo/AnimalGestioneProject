# アプリアイコン設定手順

このフォルダにはアプリアイコンの生成に必要なファイルが含まれています。以下の手順に従って、アプリにアイコンを設定してください。

## 方法1: Pythonスクリプトを使用する (推奨)

1. 以下の依存関係をインストールします:
   ```
   pip install cairosvg pillow
   ```

2. スクリプトを実行します:
   ```
   python generate_icons.py
   ```

3. 生成された `AppIconSet.appiconset` フォルダ内のファイルを、XcodeのAssets.xcassetsの `AppIcon.appiconset` フォルダの内容と置き換えます。

## 方法2: 手動でアイコンを生成する

1. `app_icon.svg` を使用して、以下のサイズのPNG画像を生成します:
   - 1024x1024 (App Store)
   - 180x180, 120x120 (iPhone)
   - 167x167, 152x152 (iPad)
   - 87x87, 80x80, 76x76, 60x60, 58x58, 40x40, 29x29, 20x20 (その他のサイズ)

2. これらの画像を `AppIconSet.appiconset` フォルダに配置します。

3. `AppIconSet.appiconset` フォルダの内容をXcodeのAssets.xcassetsの `AppIcon.appiconset` フォルダにコピーします。

## 方法3: Xcodeを使用する (最も簡単)

1. Xcodeで「Assets.xcassets」を開きます。

2. 「AppIcon」を選択します。

3. 「Attributes Inspector」(右側のパネル) で、「App Icons and Launch Images」セクションを探します。

4. 「App Icon Source」ドロップダウンから「New iOS App Icon」を選択します。

5. ここで `app_icon.svg` ファイルをドラッグアンドドロップするか、「+」ボタンをクリックして追加します。

6. Xcodeが自動的に必要なサイズのアイコンを生成します。

## その他の方法

オンラインツールを使用することもできます:

- [AppIconMaker](https://appiconmaker.co/)
- [MakeAppIcon](https://makeappicon.com/)
- [IconKitchen](https://icon.kitchen/)

これらのサイトに `app_icon.svg` をアップロードし、生成されたアイコンセットをダウンロードしてXcodeのAssets.xcassetsに配置します。

## アイコンのカスタマイズ

`app_icon.svg` ファイルを編集することで、アイコンのデザインを変更できます。SVGエディタ (Adobe Illustrator, Inkscape, Figma など) を使用してカスタマイズしてください。
