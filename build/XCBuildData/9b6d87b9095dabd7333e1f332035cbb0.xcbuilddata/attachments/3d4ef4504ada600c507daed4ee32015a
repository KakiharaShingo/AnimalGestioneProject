#!/bin/sh
# リソースを探す
RESOURCES_DIR="${SRCROOT}/Pods"
OUTPUT_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# 出力ディレクトリを作成
mkdir -p "${OUTPUT_DIR}"

# リソースバンドルを探して、コピーする
find "${RESOURCES_DIR}" -name "GoogleMobileAdsResources.bundle" -type d | while read -r BUNDLE; do
  echo "Copying: ${BUNDLE} to ${OUTPUT_DIR}"
  cp -R "${BUNDLE}" "${OUTPUT_DIR}/"
done

find "${RESOURCES_DIR}" -name "UserMessagingPlatformResources.bundle" -type d | while read -r BUNDLE; do
  echo "Copying: ${BUNDLE} to ${OUTPUT_DIR}"
  cp -R "${BUNDLE}" "${OUTPUT_DIR}/"
done

# 完了メッセージ
echo "Google resources copied successfully"

