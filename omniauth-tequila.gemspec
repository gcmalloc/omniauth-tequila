# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth/tequila/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Chris Bird']
  gem.email         = ['chris@twowordbird.com']
  gem.description   = <<-EOF
  This is an OmniAuth 1.0 compatible strategy that authenticates via EPFL's Tequila protocol. By default, it connects to EPFL's Tequila server, but it is fully configurable.
EOF
  gem.summary       = %q{Tequila Strategy for OmniAuth}
  gem.homepage      = 'https://github.com/twowordbird/omniauth-tequila'
  gem.license       = 'MIT'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'omniauth-tequila'
  gem.require_paths = ['lib']
  gem.version       = Omniauth::Tequila::VERSION

  gem.add_dependency 'omniauth',                '>= 1.2.0'
  gem.add_dependency 'addressable',             '~> 2.3'

  gem.add_development_dependency 'rake',        '~> 0.9'
  gem.add_development_dependency 'webmock',     '~> 1.8.11'
  gem.add_development_dependency 'simplecov',   '~> 0.7.1'
  gem.add_development_dependency 'rspec',       '~> 2.11'
  gem.add_development_dependency 'rack-test',   '~> 0.6'

  gem.add_development_dependency 'awesome_print'

end
