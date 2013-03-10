# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "gerber"
  gem.version       = 0

  gem.authors       = ["Brandon Fosdick"]
  gem.email         = ["bfoz@bfoz.net"]
  gem.description   = %q{Tools for working with Gerber and Extended Gerber files}
  gem.summary       = %q{Everything you need to read and write Gerber RS-274-D and Extended Gerber RS-274-X files}
  gem.homepage      = "http://github.com/bfoz/gerber"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency  'geometry', '>= 6'
end
