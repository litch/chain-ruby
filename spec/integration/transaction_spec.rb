require 'spec_helper'

describe Chain::Transaction do

  describe "A simple transaction" do
    it "should be valid" do
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

  describe "Calculating change." do
    it "should consider unspents, outputs and a fee" do
      expect(Chain).to receive(:get_addresses_unspents).and_return([{
        "transaction_hash" => "0bf0de38c26195919179f42d475beb7a6b15258c38b57236afdd60a07eddd2cc",
        "output_index" => 0,
        "value" => 10000,
        "addresses" => [
            "1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb"
        ],
        "script" => "OP_DUP OP_HASH160 c629680b8d13ca7a4b7d196360186d05658da6db OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex" => "76a914c629680b8d13ca7a4b7d196360186d05658da6db88ac",
        "script_type" => "pubkeyhash",
        "required_signatures" =>  1,
        "spent" => false,
        "confirmations" => 8758
      }])

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

end
