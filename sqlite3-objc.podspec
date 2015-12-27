Pod::Spec.new do |spec|
spec.name         = 'sqlite3-objc'
spec.version      = '0.0.1'
spec.license      = { :type => 'MIT' }
spec.homepage     = 'https://github.com/mconintet/sqlite3-objc.git'
spec.authors      = { 'mconintet' => 'mconintet@gmail.com' }
spec.summary      = 'A simple toolkit to make sqlite in Objective-C to be little easier.'
spec.source       = { :git => 'https://github.com/mconintet/sqlite3-objc.git', :tag => '0.0.1' }
spec.source_files = 'sqlite3-objc'
spec.ios.deployment_target = '8.0'
end
