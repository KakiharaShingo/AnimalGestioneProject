#!/bin/sh
# GoogleMobileAdsのリソースを手動でコピー
SOURCE_DIR="${SRCROOT}/Pods/Google-Mobile-Ads-SDK"
RESOURCES_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# リソースディレクトリが存在することを確認
mkdir -p "${RESOURCES_DIR}"

# リソースをコピー
if [ -d "${SOURCE_DIR}/Resources" ]; then
  cp -R "${SOURCE_DIR}/Resources/"* "${RESOURCES_DIR}/"
fi

# バンドルをコピー
if [ -d "${PODS_CONFIGURATION_BUILD_DIR}/Google-Mobile-Ads-SDK/GoogleMobileAdsResources.bundle" ]; then
  cp -R "${PODS_CONFIGURATION_BUILD_DIR}/Google-Mobile-Ads-SDK/GoogleMobileAdsResources.bundle" "${RESOURCES_DIR}/"
fi

if [ -d "${PODS_CONFIGURATION_BUILD_DIR}/GoogleUserMessagingPlatform/UserMessagingPlatformResources.bundle" ]; then
  cp -R "${PODS_CONFIGURATION_BUILD_DIR}/GoogleUserMessagingPlatform/UserMessagingPlatformResources.bundle" "${RESOURCES_DIR}/"
fi

exit 0

