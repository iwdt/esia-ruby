# frozen_string_literal: true

require_relative 'lib/esia/version'

Gem::Specification.new do |spec|
  spec.name = 'esia-ruby'
  spec.version = ESIA::VERSION
  spec.authors = ['Ivan Naumov']
  spec.email = ['ivannaymov@gmail.com']
  spec.homepage = 'https://gitlab.rzdit.ru/inaumov/esia'
  spec.license = 'MIT'
  spec.summary = '  '
  spec.metadata['source_code_uri'] = 'https://gitlab.rzdit.ru/inaumov/esia.git'
  spec.metadata['changelog_uri'] = 'https://gitlab.rzdit.ru/inaumov/esia/CHANGELOG'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7')
  spec.extensions = %w[
    ext/esia/extconf.rb
  ]
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['lib/**/*', 'ext/**/*', 'CHANGELOG', 'README.md', 'Gemfile', 'Rakefile']
  end

  spec.add_dependency 'ffi'
  spec.add_dependency 'jwt'

  # Rubocop
  spec.add_development_dependency 'rubocop', '~> 1.30'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.11'

  # Rake
  spec.add_development_dependency 'rake'

  # Tesing
  spec.add_development_dependency 'rspec', '~> 3.11.0'
end
