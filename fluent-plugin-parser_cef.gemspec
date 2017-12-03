# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-parser_cef"
  spec.version       = File.read("VERSION").strip
  spec.authors       = ["Tomoyuki Sugimura"]
  spec.email         = ["tomoyuki.sugimura@gmail.com"]
  spec.description   = %q{common event format(CEF) parser plugin for fluentd}
  spec.summary       = %q{common event format(CEF) parser plugin, currently only 'syslog' format is permitted}
  spec.homepage      = "https://github.com/lunardial/fluent-plugin-parser_cef"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.1"

  spec.add_runtime_dependency "fluentd", ">= 0.14.0", "< 2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "test-unit"
end
