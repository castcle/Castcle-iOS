platform :ios, '13.0'

use_frameworks!

workspace 'Castcle-iOS'

def share_pods
  pod 'AppCenter'
  pod 'IGListKit'
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
