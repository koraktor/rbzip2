require 'rspec/core'
require 'rspec/expectations'

require 'rbzip2'

include RBzip2

RSpec.configure do |config|
  config.color_enabled = true
  config.mock_framework = :mocha
end

def fixture(file)
  File.new File.join(File.dirname(__FILE__), file)
end
