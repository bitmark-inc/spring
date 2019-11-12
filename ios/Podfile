# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# ignore all warnings from all pods
inhibit_all_warnings!

def sharedPods
  pod 'BitmarkSDK/RxSwift', git: 'https://github.com/bitmark-inc/bitmark-sdk-swift.git', branch: 'master'
  pod 'Intercom'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.4.1'

  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'RxFlow'
  pod 'RxOptional'
  pod 'Moya/RxSwift', git: "https://github.com/Moya/Moya.git", tag: "14.0.0-beta.3"
  pod 'RealmSwift'
  pod "RxRealm"
  pod "RxTheme"

  pod 'IQKeyboardManagerSwift'
  pod 'Hero'
  pod 'PanModal'
  pod 'SVProgressHUD'
  pod 'NotificationBannerSwift'
  pod 'R.swift'
  pod 'SnapKit'

  pod 'SwifterSwift'

  pod 'XCGLogger', '~> 7.0.0'
    
  pod 'Charts'
  pod 'ChartsRealm'
  
end

target 'Synergy' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Synergy
  sharedPods

  target 'SynergyTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
