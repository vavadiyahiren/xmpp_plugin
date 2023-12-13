#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xmpp_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xmpp_plugin'
  s.version          = '2.2.7'
  s.summary          = 'Xmpp plugin which helps to connect with xmpp via native channels and native libs like smack android and ios via xmppframework'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'https://github.com/vavadiyahiren/xmpp_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'hiren@xrstudio.in' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'XMPPFramework/Swift'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
