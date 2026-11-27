require_relative 'lib/diff_match_patch_ext/version'

Gem::Specification.new do |spec|
  spec.name = 'diff_match_patch_ext'
  spec.version = DiffMatchPatchExt::VERSION
  spec.summary = 'Ruby binding for the diff_match_patch C++ library'
  spec.description = 'Drop-in replacement for diff_match_patch_native that uses Ruby\'s C API instead of rice, ' \
                     'so it builds on Ruby 3.'
  spec.authors = ['All American Entertainment']
  spec.homepage = 'https://github.com/allamerican/diff_match_patch_ext'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.6'

  spec.files = Dir['lib/**/*.rb', 'ext/**/*.{rb,cpp,h}', 'LICENSE', 'README.md']
  spec.extensions = ['ext/diff_match_patch_ext/extconf.rb']
  spec.require_paths = ['lib']
end
