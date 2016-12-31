source 'https://rubygems.org'

group :development do
  gem 'ffi', '~> 1.9.0', :platform => :ruby
  gem 'mocha', '~> 0.14.0'
  gem 'rake', '~> 10.1.0'
  gem 'rspec-core', '~> 2.14.4'
  gem 'rspec-expectations', '~> 2.14.0'
  gem 'yard', '~> 0.8.6'
end

group :test do
  gem 'coveralls', '~> 0.8', :require => false
end

platforms :jruby, :ruby_18, :ruby_19 do
  gem 'json', '< 2'
  gem 'term-ansicolor', '< 1.4'
  gem 'tins', '< 1.7'
end
