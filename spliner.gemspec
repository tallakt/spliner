# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "spliner"

Gem::Specification.new do |s|
  s.name = "spliner"
  s.version = Spliner::VERSION
  s.authors = ["Tallak Tveide"]
  s.email = ["tallak@tveide.net"]
  s.homepage = "http://www.github.com/tallakt/spliner"
  s.summary = %q{Cubic spline interpolation library}
  s.description = %q{Simple library to perform cubic spline interpolation based on key X,Y values}
  s.required_ruby_version = '>= 1.9.1'

  s.rubyforge_project = "spliner"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_runtime_dependency "clamp", '~> 0.3'
  s.add_development_dependency "rspec", '~> 2.11'
  s.add_development_dependency "rake", '~> 0.9'
end
