java_import 'javax.xml.bind.DatatypeConverter'
java_import 'java.math.BigInteger'
java_import 'org.bitcoinj.core.ECKey'
java_import 'org.bitcoinj.core.Coin'
java_import 'org.bitcoinj.core.Address'
java_import 'org.bitcoinj.core.AddressFormatException'
java_import 'org.bitcoinj.core.ScriptException'
java_import 'org.bitcoinj.script.ScriptBuilder'
java_import 'org.bitcoinj.core.Utils'
java_import 'org.bitcoinj.core.Transaction'
java_import 'org.bitcoinj.core.Base58'
java_import 'org.bitcoinj.core.DumpedPrivateKey'
java_import 'org.bitcoinj.core.NetworkParameters'

require 'chain/chain_java_utils'

module Chain
  class Sweeper
    attr_reader :amount, :transaction, :raw_transaction

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

    def sweep!
      unspents = Chain.get_addresses_unspents(@from_keys.keys)
      raise(MissingUnspentsError) if unspents.nil? or unspents.empty?
      build_transaction_from_unspents(unspents)
      sign_transaction
      send_transaction
    end

    private

    def sign_transaction
      @transaction.inputs.each_with_index do |input, i|
        script_sig = build_transaction_input_script_sig(@transaction, i, @from_keys.values.first)
        input.setScriptSig(script_sig)
        input.verify
      end
      @transaction.verify
    end

    def send_transaction
      @raw_transaction = DatatypeConverter.printHexBinary(@transaction.unsafeBitcoinSerialize());

      Chain.send_transaction(@raw_transaction)
    end

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk|
        ChainUtils.key_from_base58_string(pk)
      }
      Hash[keys.map{|key| [key.toAddress(ChainUtils.network_params).toString(), key] }]
    end


    def build_transaction_from_unspents(unspents)
      @transaction = Transaction.new(ChainUtils.network_params).tap do |builder|
        @amount = unspents.map {|u| u["value"]}.reduce(:+) - @options[:fee]

        unspents.each do |unspent|
          output_index = unspent['output_index']
          input = ChainUtils.fetch_transaction(unspent['transaction_hash'])

          output = input.getOutput(output_index)
          builder.addInput(output)
        end

        builder.addOutput(Coin.valueOf(@amount), Address.new(ChainUtils.network_params, @to_addr))
      end
    end

    # @transaction [Object] Transaction returned from `#build_transaction_from_unspents`.
    # @input_index [Fixnum] The index of the input.
    # @private_key [ECKey] The private key used to sign the input at this index.
    # @return [String] The script_sig used for signing this (and only this) transaction.
    # @raise [Coinmux::Error]
    def build_transaction_input_script_sig(transaction, input_index, private_key)
      tx_input = get_unspent_tx_input(transaction, input_index)
      key = private_key
      connected_pub_key_script = tx_input.getOutpoint().getConnectedPubKeyScript()
      script_public_key = tx_input.getOutpoint().getConnectedOutput().getScriptPubKey().to_s

      signature = transaction.calculateSignature(input_index, key, connected_pub_key_script, Transaction::SigHash::ALL, false)
      script_sig = ScriptBuilder.createInputScript(signature, key)

      script_sig
    end

    # @transaction [Object] Transaction returned from `#build_transaction_from_unspents`
    # @input_index [Fixnum] The index of the input.
    # @return [TransactionInput] A verified unspent input.
    # @raise [Chain::Error]
    def get_unspent_tx_input(transaction, input_index)
      input_index = input_index.to_s.to_i
      raise Chain::Error, "Invalid input index" if input_index < 0 || input_index >= transaction.getInputs().size()
      tx_input = transaction.getInput(input_index)
      raise Chain::Error, "No connected output: #{tx_input}" if tx_input.getOutpoint().getConnectedOutput().nil?
      raise Chain::Error, "Signing already signed transaction: #{tx_input}" if tx_input.getScriptBytes().length != 0
      begin
        tx_input.getScriptSig().correctlySpends(transaction, input_index, tx_input.getOutpoint().getConnectedOutput().getScriptPubKey())
        raise Chain::Error, "Input already spent: #{tx_input}"
      rescue ScriptException
        # input not spent... what we want
      end

      tx_input
    end

  end
end