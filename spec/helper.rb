require 'rspec/core'
require 'rspec/expectations'

require 'coveralls'
Coveralls.wear!

require 'rbzip2'

include RBzip2

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.mock_framework = :mocha
end

def fixture(file)
  File.new File.join(File.dirname(__FILE__), file)
end
