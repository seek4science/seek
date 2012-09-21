# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nailgun"
  s.version     = "0.0.3"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Amar Daxini"]
  s.email       = ["amardaxini@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/nailgun"
  s.summary     = %q{XHTML to PDF using Flying Saucer java library}
  s.description = %q{XHTML to PDF using Flying Saucer java library}
  s.rubyforge_project = "nailgun"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
