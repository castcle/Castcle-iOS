platform :ios, '13.0'

use_frameworks!

workspace 'Castcle-iOS'

def share_pods
  pod 'AppCenter'
  pod 'IGListKit'
  pod 'MHWebViewController'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Lightbox'
  pod 'SnackBar.swift'
  pod 'Defaults'
  pod 'SwiftColor'
  pod 'ESTabBarController-swift'
  pod 'Kingfisher'
  pod 'Moya'
  pod 'SwiftyJSON'
  pod 'ActiveLabel'
  pod 'Nantes'
  pod 'PanModal'
end

# Castcle-iOS
target 'Castcle-iOS' do
    project 'Castcle-iOS.xcodeproj'
    share_pods
end

# Component
 target 'Component' do
     project 'Component/Component.xcodeproj'
     share_pods
 end

# Feed
 target 'Feed' do
     project 'Feed/Feed.xcodeproj'
     share_pods
 end

# Search
 target 'Search' do
     project 'Search/Search.xcodeproj'
     share_pods
 end

# Authen
 target 'Authen' do
     project 'Authen/Authen.xcodeproj'
     share_pods
 end

# Profile
 target 'Profile' do
     project 'Profile/Profile.xcodeproj'
     share_pods
 end
