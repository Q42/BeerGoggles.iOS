
platform :ios, '11.0'

target 'Uncheckd' do
  use_frameworks!

  pod 'Promissum', :git => 'https://github.com/tomlokhorst/Promissum', :branch => 'develop'
  pod 'R.swift'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Valet'
  pod 'CancellationToken'
  
end

# Support for legacy pods still on Swift 3
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['Promissum'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
      end
    end
    if ['TesseractOCRiOS'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end
