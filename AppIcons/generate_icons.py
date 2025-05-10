#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
アプリアイコン生成スクリプト
このスクリプトはSVGファイルからiOSアプリ用のアイコンセットを生成します。
必要な依存関係：
- cairosvg (SVGをPNGに変換)
- pillow (画像処理)

インストール方法:
pip install cairosvg pillow

使用方法:
1. SVGファイルをこのディレクトリに "app_icon.svg" という名前で保存します
2. このスクリプトを実行します: python generate_icons.py
3. 生成されたアイコンをXcodeのAssets.xcassetsに配置します
"""

import os
import json
from io import BytesIO
try:
    import cairosvg
    from PIL import Image
except ImportError:
    print("依存関係をインストールしてください: pip install cairosvg pillow")
    exit(1)

# iOS アプリアイコンサイズ (ピクセル単位)
IOS_ICON_SIZES = [
    1024,  # App Store
    180,   # iPhone notification iOS 7-14
    120,   # iPhone notification iOS 7-14
    167,   # iPad Pro
    152,   # iPad, iPad mini
    87,    # iPhone 6 Plus
    80,    # Settings
    76,    # Settings
    60,    # Settings
    58,    # Settings
    40,    # Spotlight
    29,    # Spotlight
    20     # Spotlight
]

# アイコンセット用の Contents.json ファイル
CONTENTS_JSON = {
    "images": [
        {
            "filename": "AppIcon-1024x1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
            "scale": "1x"
        }
    ],
    "info": {
        "author": "xcode",
        "version": 1
    }
}

def create_icon_from_svg(svg_path, output_dir, size):
    """SVGファイルから指定されたサイズのPNGアイコンを生成します"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    output_file = os.path.join(output_dir, f"AppIcon-{size}x{size}.png")
    
    try:
        # SVGをPNGに変換
        png_data = cairosvg.svg2png(url=svg_path, output_width=size, output_height=size)
        
        # 画像を開いて保存
        img = Image.open(BytesIO(png_data))
        img.save(output_file, "PNG")
        
        print(f"{output_file} を生成しました")
        return True
    except Exception as e:
        print(f"エラー: {output_file} を生成できませんでした - {str(e)}")
        return False

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    svg_path = os.path.join(script_dir, "app_icon.svg")
    output_dir = os.path.join(script_dir, "AppIconSet.appiconset")
    
    if not os.path.exists(svg_path):
        print(f"エラー: {svg_path} が見つかりません。このディレクトリにSVGファイルを「app_icon.svg」という名前で保存してください。")
        return
    
    # 出力ディレクトリを作成
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # すべてのサイズのアイコンを生成
    for size in IOS_ICON_SIZES:
        create_icon_from_svg(svg_path, output_dir, size)
    
    # Contents.json ファイルを作成
    contents_json_path = os.path.join(output_dir, "Contents.json")
    with open(contents_json_path, 'w', encoding='utf-8') as f:
        json.dump(CONTENTS_JSON, f, indent=2)
    
    print("\n生成完了！")
    print(f"生成されたアイコンは {output_dir} に保存されています")
    print("\n使用方法:")
    print("1. Xcodeで「Assets.xcassets」を開きます")
    print("2. 「AppIcon」を右クリックして「Show in Finder」を選択します")
    print("3. 生成されたアイコンファイルを「AppIcon.appiconset」フォルダにコピーします")
    print("4. Xcodeでプロジェクトを再ビルドします")
    
if __name__ == "__main__":
    main()
