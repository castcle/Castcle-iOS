platform :ios, '13.0'

use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

workspace 'Castcle-iOS'

def share_pods
  pod 'IGListKit'
  pod 'Lightbox'
  pod 'UITextView+Placeholder'
  pod 'XLPagerTabStrip'
  pod 'DropDown'
  pod 'SVPinView'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
  pod 'GTProgressBar'
  pod 'PopupDialog'
end

# Castcle-iOS
target 'Castcle-iOS' do
    project 'Castcle-iOS.xcodeproj'
    share_pods
    pod 'AppCenter'
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

# Networking
 target 'Networking' do
     project 'Networking/Networking.xcodeproj'
     share_pods
 end

# Post
 target 'Post' do
     project 'Post/Post.xcodeproj'
     share_pods
 end

# Setting
 target 'Setting' do
     project 'Setting/Setting.xcodeproj'
     share_pods
 end

# Setting
 target 'Notification' do
     project 'Notification/Notification.xcodeproj'
     share_pods
 end

# Ads
 target 'Ads' do
     project 'Ads/Ads.xcodeproj'
     share_pods
 end
