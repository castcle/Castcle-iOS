platform :ios, '12.0'

use_frameworks!

workspace 'Castcle-iOS'

def share_pods
  pod 'AppCenter'
  pod 'Defaults'
  pod 'SwiftDate'
  pod 'Moya'
  pod 'SwiftyJSON'
  pod 'Kingfisher'
end

# Castcle-iOS
target 'Castcle-iOS' do
    project 'Castcle-iOS.xcodeproj'
    share_pods
end

# Core
 target 'Core' do
     project 'Core/Core.xcodeproj'
     share_pods
 end
