class ChainUtils

  def self.fetch_transaction(transaction_hash)
    bytes = webbtc_get_bin("/tx/#{transaction_hash}.bin").unpack('c*').to_java(:byte)
    Transaction.new(network_params, bytes)
  end

  def self.webbtc_host
    Chain::block_chain == 'bitcoin' ? 'http://webbtc.com' : 'http://test.webbtc.com'
  end

  def self.webbtc_get_bin(path)
    uri = URI("#{webbtc_host}#{path}")
    p response = Net::HTTP.get_response(uri)
    if response.code == '200'
      return response.body
    else
      p "CONNECTION ERROR TO WEBBTC - trying again in 500ms"
      sleep 0.5
      return webbtc_get_bin(path)
    end
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
    Chain::block_chain == 'bitcoin' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
  end
end
