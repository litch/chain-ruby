require 'net/http'
require 'net/https'
require 'json'
require 'thread'
require 'uri'

# A module that wraps the Chain SDK.
module Chain
  if RUBY_PLATFORM == 'java'
    Dir[File.join(File.dirname(__FILE__), 'jar', '*.jar')].each { |filename| require filename }
    autoload :ChainTransaction, 'chain/transactionj'
    autoload :Sweeper, 'chain/sweeperj'
  else
    autoload :ChainTransaction, 'chain/transaction'
    autoload :Sweeper, 'chain/sweeper'
  end

  autoload :Client, 'chain/client'
  autoload :Conn, 'chain/conn'

  GUEST_KEY = 'GUEST-TOKEN'
  CHAIN_URL = 'https://api.chain.com'

  # A collection of root certificates used by api.chain.com
  CHAIN_PEM = File.expand_path('../../chain.pem', __FILE__)

  # Prefixed in the path of HTTP requests.
  API_VERSION = 'v2'

  # Raised when an unexpected error occurs in either
  # the HTTP request or the parsing of the response body.
  ChainError = Class.new(StandardError)

  @config = { :network => "bitcoin" }
  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each { |k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym }
  end

  def self.default_client=(c)
    @default_client = c
  end

  def self.default_client
    @default_client ||= Client.new
  end

  def self.method_missing(sym, *args, &block)
    default_client.send(sym, *args, &block)
  end

  def self.url
    @url ||= begin
      URI(ENV['CHAIN_URL'] || CHAIN_URL).tap do |u|
        u.user ||= GUEST_KEY
      end
    end
  end

  def self.block_chain
    @config[:network]
  end

end
