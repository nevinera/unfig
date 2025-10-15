RSpec.describe Unfig do
  describe ".load_options" do
    subject(:load_options) { described_class.load_options(values:, format:, banner:, env:, argv:, config:) }

    let(:inputs) { {} }
    let(:format) { :hash }
    let(:banner) { nil }
    let(:argv) { ["--foo"] }
    let(:env) { {"BAZ" => "59"} }
    let(:config) { "/tmp/config.yml" }

    let(:values) do
      {
        foo: {type: "boolean", default: false, description: "The Foo"},
        bar: {type: "string", default: [], description: "The Bar", multi: true},
        baz: {type: "integer", default: 21, description: "The Baz", enabled: ["long", "env"], short: "r"}
      }
    end

    let(:config_yaml) { "{baz: 56, foo: false, bar: ['yeah', 'nope']}" }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(config).and_return(config_yaml)
    end

    it "produces the expected result" do
      expect(load_options).to eq({foo: true, bar: ["yeah", "nope"], baz: 59})
    end
  end
end
