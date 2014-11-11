class ChainUtils

  def self.fetch_transaction(transaction_hash)
    bytes = webbtc_get_bin("/tx/#{transaction_hash}.bin").unpack('c*').to_java(:byte)
    Transaction.new(network_params, bytes)
  end

  def self.webbtc_get_bin(path)
    host = 'http://test.webbtc.com'
    uri = URI("#{host}#{path}")
    response = Net::HTTP.get_response(uri)
    response.body
  end

  def self.key_from_base58_string(base58_string)
    DumpedPrivateKey.new(network_params, base58_string).getKey()
  end

  def self.private_key_to_address(base58_string)
    ec_key = DumpedPrivateKey.new(network_params, base58_string).getKey()
    address = ec_key.toAddress(network_params)
  end

  class Chain::Error < StandardError
  end

  def self.network_params
    # Chain::Config.instance.bitcoin_network == 'mainnet' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
    NetworkParameters.testNet3()
  end
end
