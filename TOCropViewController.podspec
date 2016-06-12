Pod::Spec.new do |s|
  s.name     = 'TOCropViewController'
  s.version  = '2.0.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A view controller that allows users to crop UIImage objects.'
  s.homepage = 'https://github.com/TimOliver/TOCropViewController'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOCropViewController.git', :tag => '2.0.0' }
  s.platform = :ios, '7.0'

  s.source_files = 'TOCropViewController/**/*.{h,m}'
  s.resource_bundles = {
    'TOCropViewControllerBundle' => ['TOCropViewController/**/*.lproj']
  }
  s.requires_arc = true
end
