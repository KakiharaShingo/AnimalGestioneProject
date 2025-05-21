install! 'cocoapods', 
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true

platform :ios, '14.0'

target 'AnimalGestioneProject' do
  use_frameworks!

  # Pods for AnimalGestioneProject
  pod 'Google-Mobile-Ads-SDK', '~> 12.4.0'

  target 'AnimalGestioneProjectTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'AnimalGestioneProjectUITests' do
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      
      # 追加の設定
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end 