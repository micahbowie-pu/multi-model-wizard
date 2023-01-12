# frozen_string_literal: true

require_relative "lib/multi_model_wizard/version"

Gem::Specification.new do |spec|
  spec.name = 'multi_model_wizard'
  spec.version = MultiModelWizard::VERSION
  spec.authors = ["micahbowie-pu"]
  spec.email = ["mbowie@meazurelearning.com"]

  spec.summary = 'Creates a smart object for your forms or wizards.This object can update and save multiple active record models at once.'
  spec.description = 'Creates a smart object for your forms or wizards.This object can update and save multiple active record models at once.'
  spec.homepage = 'https://github.com/ProctorU'
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = 'https://rubygems.org/'
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activemodel', '>= 5.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'wicked', '~> 2.0'
end
