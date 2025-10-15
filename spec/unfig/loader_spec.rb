RSpec.describe Unfig::Loader do
  subject(:loader) { described_class.new(values:, format:, banner:, **inputs) }

  let(:inputs) { {} }
  let(:format) { :hash }
  let(:banner) { nil }

  let(:values) do
    {
      foo: {type: "boolean", default: false, description: "The Foo"},
      bar: {type: "string", default: [], description: "The Bar", multi: true},
      baz: {type: "integer", default: 21, description: "The Baz", enabled: ["long", "env"], short: "r"}
    }
  end

  let(:config_yaml) { "{}" }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("/tmp/config.yml").and_return(config_yaml)
  end

  describe "#read" do
    subject(:read) { loader.read }

    context "when format is :hash" do
      let(:format) { :hash }

      context "when there are no inputs given" do
        before { stub_const("ARGV", ["--foo"]) }
        with_env("BAZ" => "59")

        it "produces the expected result" do
          expect(read).to eq({foo: true, bar: [], baz: 59})
        end
      end

      context "when some inputs are given" do
        let(:inputs) { {argv: ["--foo"], env: {"BAZ" => "59"}, config: "/tmp/config.yml"} }
        let(:config_yaml) { "{baz: 56, foo: false, bar: ['yeah', 'nope']}" }

        it "produces the expected result" do
          expect(read).to eq({foo: true, bar: ["yeah", "nope"], baz: 59})
        end
      end
    end

    context "when format is :struct" do
      let(:format) { :struct }

      it "is an instantiated struct" do
        expect(read.class.ancestors).to include(Struct)
      end

      context "when there are no inputs given" do
        before { stub_const("ARGV", ["--foo"]) }
        with_env("BAZ" => "59")

        it "produces the expected result" do
          expect(read).to have_attributes(foo: true, bar: [], baz: 59)
        end
      end

      context "when some inputs are given" do
        let(:inputs) { {argv: ["--foo"], env: {"BAZ" => "59"}, config: "/tmp/config.yml"} }
        let(:config_yaml) { "{baz: 56, foo: false, bar: ['yeah', 'nope']}" }

        it "produces the expected result" do
          expect(read).to have_attributes(foo: true, bar: ["yeah", "nope"], baz: 59)
        end
      end
    end

    context "when format is :openstruct" do
      let(:format) { :openstruct }
      it { is_expected.to be_an(OpenStruct) }

      context "when there are no inputs given" do
        before { stub_const("ARGV", ["--foo"]) }
        with_env("BAZ" => "59")

        it "produces the expected result" do
          expect(read).to have_attributes(foo: true, bar: [], baz: 59)
        end
      end

      context "when some inputs are given" do
        let(:inputs) { {argv: ["--foo"], env: {"BAZ" => "59"}, config: "/tmp/config.yml"} }
        let(:config_yaml) { "{baz: 56, foo: false, bar: ['yeah', 'nope']}" }

        it "produces the expected result" do
          expect(read).to have_attributes(foo: true, bar: ["yeah", "nope"], baz: 59)
        end
      end
    end

    context "when format is :wombat" do
      let(:format) { :wombat }

      it "raises ArgumentError" do
        expect { read }.to raise_error(ArgumentError, /cannot return results in the format 'wombat'/)
      end
    end
  end
end
