#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dive_av.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dive_av'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author          = 'Larry Aasen'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.frameworks  = 'AVFoundation'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.2'
end
