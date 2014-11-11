# import 'org.bitcoinj.core'
# import 'org.spongycastle.crypto.KeyGenerationParameters'
java_import 'javax.xml.bind.DatatypeConverter'
java_import 'java.math.BigInteger'
java_import 'org.bitcoinj.core.ECKey'
java_import 'org.bitcoinj.core.Coin'
java_import 'org.bitcoinj.core.Address'
java_import 'org.bitcoinj.core.AddressFormatException'
java_import 'org.bitcoinj.core.Utils'
java_import 'org.bitcoinj.core.Transaction'
java_import 'org.bitcoinj.core.Base58'
java_import 'org.bitcoinj.core.DumpedPrivateKey'
java_import 'org.bitcoinj.core.NetworkParameters'

module Chain
  # The Chain::Transaction is a mechanism to create new transactions
  # for the bitcoin network.
  class ChainTransaction
    DEFAULT_FEE = 10_000
    MissingUnspentsError = Class.new(StandardError)
    MissingInputsError = Class.new(StandardError)
    InsufficientFundsError = Class.new(StandardError)

    # Create a new Transaction which will be ready for hex encoding and
    # subsequently delivery to the Chain API.
    # inputs:: Array of base58 encoded private keys. The unspent outputs of these keys will be consumed.
    # ouputs:: Hash with base58 encoded public key hashes keys and satoshi values.
    # fee:: Satoshi value representing the fee added to the transaction. Relies on DEFAULT_FEE when nil.
    # change_address:: Bash58 encoded hash of public key. To where change will be sent. See Transaction#change for details on how change is calculated.
    def initialize(inputs: [], outputs: {}, fee: nil, change_address: nil)
      @inputs = strs_to_keys(inputs)
      @outputs = outputs
      @fee = fee
      @change_address = change_address

      raise(MissingInputsError) unless @inputs.length > 0
    end

    # Returns the hex encoded transaction data.
    def hex
      @hex = DatatypeConverter.printHexBinary(build.unsafeBitcoinSerialize());
    end

    # Send's the hex encoded transaction data to the Chain API.
    def send
      Chain.send_transaction(hex)
    end

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk|
        ChainUtils.key_from_base58_string(pk)
      }
      Hash[keys.map{|key| [key.toAddress(ChainUtils.network_params).toString(), key] }]
    end

    # Computes a sum of the values in the collectino of UTXO
    # associated with each address in the @inputs collection.
    def unspents_amount
      unspents.map {|u| u["value"]}.reduce(:+)
    end

    # Uses the Chain batch API to fetch unspents for @inputs.
    # Value is memoized for repeated access.
    def unspents
      @unspents ||= begin
        Chain.get_addresses_unspents(@inputs.keys).tap do |unspents|
          raise(MissingUnspentsError) if unspents.nil? or unspents.empty?
        end
      end
    end

    # Computes a sum of the outputs defined in the @outputs hash.
    def outputs_amount
      @outputs.map {|addr, amount| amount}.reduce(:+)
    end

    # Uses the fee specified in the initializer xor the DEFAULT_FEE
    def fee
      @fee || DEFAULT_FEE
    end

    def change
      unspents_amount - outputs_amount - fee
    end

    # Uses the address specified in the initializer. Otherwise
    # falls back on the first address in the list of @inputs.
    def change_address
      @change_address || @inputs.keys.first
    end

    # Consumes the unspents of the addresses in the @inputs
    # Creates outputs specifed by @outputs
    # Adds an additional output to the change_address if change is greater than 0.
    def build

      raise(InsufficientFundsError) if outputs_amount > unspents_amount

      transaction = Transaction.new(ChainUtils.network_params).tap do |builder|

        @outputs.each do |addr, amount|
          builder.addOutput(Coin.valueOf(amount), Address.new(ChainUtils.network_params, addr))
        end

        if @fee and change > 0
          builder.addOutput(Coin.valueOf(amount), Address.new(ChainUtils.network_params, change_address))
        else
          builder.addOutput(Coin.valueOf(unspents_amount), Address.new(ChainUtils.network_params, change_address))
        end

        unspents.each do |unspent|
          output_index = unspent['output_index']
          input = ChainUtils.fetch_transaction(unspent['transaction_hash'])

          output = input.getOutput(output_index)
          key = @inputs[unspent['addresses'][0]]
          add_signed_input = builder.java_method :addSignedInput, [output.class, key.class]

          add_signed_input.call(output, key)
        end
      end
    end

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

  end
end

