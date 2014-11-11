require 'spec_helper'

describe Chain::Sweeper do
  describe "initialization" do
    it "requires valid inputs" do
      expect do
        Chain::Sweeper.new([], 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd').sweep!
      end.to raise_error(Chain::Sweeper::MissingUnspentsError)
    end
  end

  describe 'sending transaction' do
    it 'sends a transaction' do
      expect(Chain).
        to receive(:get_addresses_unspents).
        and_return(Fixtures['get_addresses_unspents'])

      unspents_amount = Fixtures['get_addresses_unspents'][0]['value']

      txn = Chain::Sweeper.new(
        ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd'
      )

      stub_request(:get, "http://test.webbtc.com/tx/015a930572af772ffd77257aac0dd6d87350b263ada2299cbcbdf69e618277e7.bin").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'test.webbtc.com', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => load_fixture('015a930572af772ffd77257aac0dd6d87350b263ada2299cbcbdf69e618277e7.bin'), :headers => {})

      stub_request(:put, "https://GUEST-TOKEN:@api.chain.com//v2/bitcoin/transactions").
        with { |request|
          JSON.parse(request.body)['hex'].upcase.start_with?('0100000001e77782619ef6bdbc9c29a2ad63b25073d8d60dac7a2577fd2f77'.upcase) }.
        to_return(:status => 200, :body => {transaction_hash: 12345}.to_json, :headers => {})

      txn.sweep!
      expect(txn.amount).to eq 80000
    end
  end
end
