Pod::Spec.new do |s|
    s.name             = "HxSTLParser"
    s.version          = "1.0.0"
    s.summary          = "Basic STL loader for SceneKit"
    s.description      = "Loads arbitrary STL data into SceneKit"
    s.homepage         = "https://github.com/victorgama/HxSTLParser"
    s.license          = 'MIT'
    s.author           = { "Victor Gama" => "hey@vito.io" }
    s.source           = { :git => "https://github.com/victorgama/HxSTLParser.git", :tag => s.version.to_s }
    s.platform     = :ios, '8.0'
    s.requires_arc = true
    s.source_files = 'HxSTLParser/*.h', 'HxSTLParser/*.m'
end
