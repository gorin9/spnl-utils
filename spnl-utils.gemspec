Gem::Specification.new do |s|
  s.name = 'spnl-utils'
  s.version = '0.2.0'
  s.summary = 'Standard JSON and URI plus framed HTTP helpers for Spinel'
  s.authors = ['gorin9']
  s.homepage = 'https://github.com/gorin9/spnl-utils'
  s.license = 'MIT'
  s.required_ruby_version = '>= 3.1'
  s.files = Dir['lib/**/*.rb', 'web/**/*.rb', 'spnl_*/**/*.rb', 'spnl_*.rb', 'native/*', 'bin/*', 'README.md', 'LICENSE', 'spin.toml', 'spinel-packer']
  s.require_paths = ['.']
  s.executables = []
end
