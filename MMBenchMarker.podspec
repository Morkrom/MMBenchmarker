#
# Be sure to run `pod lib lint MMBenchMarker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMBenchMarker'
  s.version          = '0.1.0'
  s.summary          = 'Benchmarking distilled'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC

  This is another simple benchmarker. It records samples in ms converted from mach_time for a given key.
  After samples have been accumulated, It logs the difference of average recording time between two keys.

  DESC

  s.homepage         = 'https://github.com/Morkrom/MMBenchMarker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Michael Mork' => 'morkrom@protonmail.ch' }
  s.source           = { :git => 'https://github.com/Morkrom/MMBenchMarker.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'MMBenchMarker/Classes/**/*'

end