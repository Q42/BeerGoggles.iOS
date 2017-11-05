# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'BeerGoggles' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'Promissum'
  pod 'R.swift'
  pod 'Fabric'
  pod 'Crashlytics', '~>  3.9'

end

# Support for legacy pods still on Swift 3
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['Promissum'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
      end
    end
  end
end
