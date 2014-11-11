require 'spec_helper'

describe Chain::Transaction do
  describe "initialization" do
    it "requires valid inputs" do
      expect do
        Chain::Transaction.new(
          inputs: [],
          outputs: {},
          change_address: 'a',
          fee: 0
        )
      end.to raise_error(Chain::Transaction::MissingInputsError)
    end
  end

  describe "change" do
    it "should consider unspents, outputs and a fee" do
      expect(Chain).
      to receive(:get_addresses_unspents).
      and_return(Fixtures['get_addresses_unspents'])

      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => 100,
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY4cKQd' => 100
        },
        change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd',
        fee: 0
      )
      expect(txn.change).to equal(9800)
    end
  end

  describe "fee" do
    it "uses initialized value" do
      txn = Chain::Transaction.new(
        inputs: [Fixtures['testnet_address']['private']],
        outputs: {},
        fee: 9
      )
      expect(txn.fee).to eq(9)
    end

    it "uses default value" do
      txn = Chain::Transaction.new(
        inputs: [Fixtures['testnet_address']['private']],
        outputs: {}
      )
      expect(txn.fee).to eq(Chain::Transaction::DEFAULT_FEE)
    end
  end

  describe "change_address" do
    it "uses the first address in the list of inputs when not specified" do
      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {}
      )
      expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd')
    end

    it "uses the specified address" do
      txn = Chain::Transaction.new(
        inputs: ['cTph6fWJeBsPUV74kd314MTKzXJttk1ByzYor5yCPEDNvyiPbw3B'],
        outputs: {},
        change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY6cKQd'
      )
      expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY6cKQd')
    end
  end

  describe "insufficient funds" do
    it "will raise an exception" do
      expect(Chain).
      to receive(:get_addresses_unspents).
      and_return(Fixtures['get_addresses_unspents'])

      unspents_amount = Fixtures['get_addresses_unspents'][0]['value']

      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => unspents_amount * 2
        }
      )
      expect {txn.build}.
        to raise_error(Chain::Transaction::InsufficientFundsError)
    end
  end

  describe 'sending transaction' do
    it 'sends a transaction' do
      expect(Chain).
        to receive(:get_addresses_unspents).
        and_return(Fixtures['get_addresses_unspents'])

      unspents_amount = Fixtures['get_addresses_unspents'][0]['value']

      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => unspents_amount
        }
      )

      stub_request(:put, "https://GUEST-TOKEN:@api.chain.com//v2/bitcoin/transactions").
         with(:body => "{\"hex\":\"0100000001e77782619ef6bdbc9c29a2ad63b25073d8d60dac7a2577fd2f77af7205935a01000000006a47304402201263acb51d38f60178b677c533dd13393dcb206c08e604e3df33f8d5610a5cd70220095eb87f7dce8ff936a6c78acd38c6554cefa9c47d81d88414394cb3b4f46603012102eaac0367f259b24f2f95fa5944e27d4b39cb0ab0b420a84ca9332329b1dba7b4ffffffff01905f0100000000001976a914bf55687b8f2eac9a5cc026d1be430c9334f804ec88ac00000000\"}",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'chain-ruby/0'}).
         to_return(:status => 200, :body => {transaction_hash: 12345}.to_json, :headers => {})

      txn.send
    end
  end

end
