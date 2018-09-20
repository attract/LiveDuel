Pod::Spec.new do |s|
  s.name             = 'LiveDuel'
  s.version          = '0.1.0'
  s.summary          = 'Some LiveDuel description.'
 
  s.description      = <<-DESC
Some LiveDuel description. No matter.
                       DESC
 
  s.homepage         = 'https://github.com/attract/LiveDuel'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AttractGroup' => 'attractdev@gmail.com' }
  s.source           = { :git => 'https://github.com/attract/LiveDuel.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'
  s.source_files = 'LiveDuel/**/*.{h,m,swift,strings}'
  s.resources = 'LiveDuel/**/*.{xib,storyboard,xcassets}'

  s.module_name = 'LiveDuelKit'

  s.ios.dependency 'FacebookCore', '~> 0.3'
  s.ios.dependency 'FacebookLogin', '~> 0.3'
  s.ios.dependency 'Alamofire', '~> 4.7'
  s.ios.dependency 'MRCountryPicker', '~> 0.0.7'
  s.ios.dependency 'Kingfisher', '~> 4.0'
  s.ios.dependency 'Socket.IO-Client-Swift', '~> 13.1.0'
  s.ios.dependency 'SRCountdownTimer'
  s.ios.dependency 'MobileVLCKit', '~> 3.0.1'

 
end