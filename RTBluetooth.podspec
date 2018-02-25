#
#  Be sure to run `pod spec lint RTBluetooth.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
s.name        = 'RTBluetooth'
s.version     = '0.0.1'
s.authors     = { 'Retouch' => '790330366@qq.com' }
s.homepage    = 'https://github.com/Retouch001/RTBluetooth'
s.summary     = 'a dropdown menu for ios like wechat homepage.'
s.source      = { :git => 'https://github.com/Retouch001/RTBluetooth.git',
:tag => s.version.to_s }
s.license     = { :type => "MIT", :file => "LICENSE" }

s.platform = :ios, '8.0'
s.requires_arc = true
s.source_files = 'RTBluetooth'

s.ios.deployment_target = '8.0'
end

