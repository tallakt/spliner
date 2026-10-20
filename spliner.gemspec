require_relative "lib/spliner/version"

Gem::Specification.new do |s|
  s.name = "spliner"
  s.version = Spliner::VERSION
  s.authors = ["Tallak Tveide"]
  s.email = ["tallak@tveide.net"]
  s.homepage = "https://github.com/tallakt/spliner"
  s.summary = "Cubic spline interpolation library"
  s.description = "Simple library to perform cubic spline interpolation based on key X,Y values"
  s.license = "MIT"
  s.required_ruby_version = ">= 3.0"
  s.metadata["rubygems_mfa_required"] = "true"

  s.files = Dir["lib/**/*.rb", "README.markdown", "LICENSE.txt"]
  s.require_paths = ["lib"]

  s.add_dependency "matrix"
end
