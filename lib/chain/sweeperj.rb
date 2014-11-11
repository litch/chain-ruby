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

require 'lib/chain/chain_java_utils'

module Chain
  class Sweeper
    attr_reader :amount

    # Unable find unspent outputs for the addresses passed into from_keystrings.
    MissingUnspentsError = Class.new(StandardError)

    @@defaults = {
      fee: 10000
    }

    # Initializes a new object that is ready for sweeping.
    #from_keystrings:: Array of base58 encoded private keys. The unspent outputs of these keys will be consumed.
    #to_addr:: The base58 encoded hash of the public keys. The collection of unspent outputs will be sent to this address.
    #:opts[:fee] => 10000:: The fee used in the sweeping transaction.
    def initialize(from_keystrings, to_addr, opts = {})
      @options = @@defaults.merge(opts)
      @from_keys = strs_to_keys(from_keystrings)
      @to_addr = to_addr
      raise(MissingUnspentsError) if @from_keys.nil? or @from_keys.empty?
    end

    # Creates a transaction and executes the network calls to perform the sweep.
    # 1. Uses Chain to fetch all unspent outputs associated with from_keystrings
    # 2. Create & Sign bitcoin transaction
    # 3. Sends the transaction to bitcoin network using Chain's API
    # Chain::ChainError will be raised if there is any network related errors.
    def sweep!
      unspents = Chain.get_addresses_unspents(@from_keys.keys)
      raise(MissingUnspentsError) if unspents.nil? or unspents.empty?

      tx = build_txn(unspents)
      rawtx = DatatypeConverter.printHexBinary(tx.unsafeBitcoinSerialize());

      Chain.send_transaction(rawtx)
    end

    private

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk|
        ChainUtils.key_from_base58_string(pk)
      }
      Hash[keys.map{|key| [key.toAddress(ChainUtils.network_params).toString(), key] }]
    end


    def build_txn(unspents)
      transaction = Transaction.new(ChainUtils.network_params).tap do |builder|
        @amount = unspents.map {|u| u["value"]}.reduce(:+) - @options[:fee]

        builder.addOutput(Coin.valueOf(@amount), Address.new(ChainUtils.network_params, @to_addr))


        unspents.each do |unspent|
          output_index = unspent['output_index']
          input = ChainUtils.fetch_transaction(unspent['transaction_hash'])

          output = input.getOutput(output_index)
          key = @from_keys[unspent['addresses'][0]]
          add_signed_input = builder.java_method :addSignedInput, [output.class, key.class]

          add_signed_input.call(output, key)
        end
      end
    end

  end
end