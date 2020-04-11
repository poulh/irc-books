# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'irc/books/version'

Gem::Specification.new do |spec|
  spec.name          = 'irc-books'
  spec.version       = Irc::Books::VERSION
  spec.authors       = ['Poul Hornsleth']
  spec.email         = ['poulh@umich.edu']

  spec.summary       = 'App to help search and download ebooks on irc'
  spec.description   = 'command-line app for searching irc for books'
  spec.homepage      = 'http://github.com/poulh/irc-books'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'cinch', '~> 2.3', '>= 2.3.4'
  spec.add_runtime_dependency 'highline', '~> 2.0', '>= 2.0.2'
  spec.add_runtime_dependency 'rubyzip', '>= 1.2.3', '< 3.0'
end
