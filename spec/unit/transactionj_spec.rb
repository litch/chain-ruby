# require 'spec_helper'

# describe Chain::TransactionJ do

#   describe "initialization" do
#     it "requires valid inputs" do
#       expect do
#         Chain::TransactionJ.new(
#           inputs: [],
#           outputs: {},
#           change_address: 'a',
#           fee: 0
#         )
#       end.to raise_error(Chain::TransactionJ::MissingInputsError)
#     end
#   end

#   describe 'utilities'  do
#     it 'can translate a private key to an address correctly' do
#       expect(
#         Chain::TransactionJ::ChainUtils.private_key_to_address('cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5').toString
#       ).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd')
#     end
#   end

#   describe "change" do
#     it "should consider unspents, outputs and a fee" do
#       expect(Chain).
#       to receive(:get_addresses_unspents).
#       and_return(Fixtures['get_addresses_unspents'])

#       txn = Chain::TransactionJ.new(
#         inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
#         outputs: {
#           'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => 100,
#           'mxxdfxLaFGePNfFJQiVkyLix3ZAjY4cKQd' => 100
#         },
#         change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd',
#         fee: 0
#       )
#       expect(txn.change).to equal(89800)
#     end
#   end

#   describe "fee" do
#     it "uses initialized value" do
#       txn = Chain::TransactionJ.new(
#         inputs: [Fixtures['testnet_address']['private']],
#         outputs: {},
#         fee: 9
#       )
#       expect(txn.fee).to eq(9)
#     end

#     it "uses default value" do
#       txn = Chain::TransactionJ.new(
#         inputs: [Fixtures['testnet_address']['private']],
#         outputs: {}
#       )
#       expect(txn.fee).to eq(Chain::TransactionJ::DEFAULT_FEE)
#     end
#   end

#   describe "change_address" do
#     it "uses the first address in the list of inputs when not specified" do
#       txn = Chain::TransactionJ.new(
#         inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
#         outputs: {}
#       )
#       expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd')
#     end

#     it "uses the specified address" do
#       txn = Chain::TransactionJ.new(
#         inputs: ['cTph6fWJeBsPUV74kd314MTKzXJttk1ByzYor5yCPEDNvyiPbw3B'],
#         outputs: {},
#         change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY6cKQd'
#       )
#       expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY6cKQd')
#     end
#   end

#   describe "insufficient funds" do
#     it "will raise an exception" do
#       expect(Chain).
#       to receive(:get_addresses_unspents).
#       and_return(Fixtures['get_addresses_unspents'])

#       unspents_amount = Fixtures['get_addresses_unspents'][0]['value']

#       txn = Chain::TransactionJ.new(
#         inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
#         outputs: {
#           'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => unspents_amount * 2
#         }
#       )
#       expect {txn.build}.
#       to raise_error(Chain::TransactionJ::InsufficientFundsError)
#     end
#   end

#   describe 'sending transaction' do
#     it 'sends a transaction' do
#       expect(Chain).
#         to receive(:get_addresses_unspents).
#         and_return(Fixtures['get_addresses_unspents'])

#       unspents_amount = Fixtures['get_addresses_unspents'].map {|u| u["value"]}.reduce(:+)

#       txn = Chain::TransactionJ.new(
#         inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
#         outputs: {
#           'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => unspents_amount
#         }
#       )

#       stub_request(:get, "http://test.webbtc.com/tx/015a930572af772ffd77257aac0dd6d87350b263ada2299cbcbdf69e618277e7.bin").
#          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'test.webbtc.com', 'User-Agent'=>'Ruby'}).
#          to_return(:status => 200, :body => load_fixture('015a930572af772ffd77257aac0dd6d87350b263ada2299cbcbdf69e618277e7.bin'), :headers => {})

#       stub_request(:put, "https://GUEST-TOKEN:@api.chain.com//v2/bitcoin/transactions").
#          with(:body => "{\"hex\":\"0100000001ccd2dd7ea060ddaf3672b5388c25156b7aeb5b472df47991919561c238def00b0000000000ffffffff0110270000000000001976a914bf55687b8f2eac9a5cc026d1be430c9334f804ec88ac00000000\"}",
#               :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'chain-ruby/0'}).
#          to_return(:status => 200, :body => {transaction_hash: 12345}.to_json, :headers => {})

#       txn.send
#     end
#   end

# end
