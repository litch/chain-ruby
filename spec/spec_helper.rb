$:.unshift("lib")
require 'chain'

require 'ffi'
require 'webmock/rspec'

require 'bundler/setup'
Bundler.require :default, :test

Chain.configure({network: :testnet3})

if RUBY_PLATFORM != 'java'
  require 'bitcoin'
  Bitcoin.network = Chain.block_chain
else

end

Fixtures = JSON.parse(File.read("./spec/data.json"))

def load_fixture(name)
  open(File.join(File.dirname(__FILE__), 'fixtures', name)) { |f| f.read }
end

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

WebMock.disable_net_connect!(allow_localhost: true)