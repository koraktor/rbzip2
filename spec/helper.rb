require 'rspec/core'
require 'rspec/expectations'

require 'rbzip2'

include RBzip2

RSpec.configure do |config|
  config.color_enabled = true
  config.extend RBzip2
  config.mock_framework = :mocha
end
