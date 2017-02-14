source 'https://rubygems.org'

group :development do
  gem 'ffi', '~> 1.9.0', :platform => :ruby
  gem 'rspec-core', '~> 3.5'
  gem 'rspec-expectations', '~> 3.5'
  gem 'yard', '~> 0.9'
end

group :test do
  gem 'coveralls', '~> 0.8', :require => false
end

if Bundler.current_ruby.jruby_1? || Bundler.current_ruby.ruby_1?
  gem 'json', '< 2'
  gem 'rake', '>= 11', '< 12', :group => :development
  gem 'term-ansicolor', '< 1.4'
  gem 'tins', '< 1.7'
else
  gem 'rake', '~> 12', :group => :development
end
