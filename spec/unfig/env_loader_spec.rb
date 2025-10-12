RSpec.describe Unfig::EnvLoader do
  subject(:env_loader) { described_class.new(params:, env:) }

  let(:params) { instance_double(Unfig::ParamsConfig, params: [foo, bar, baz, bam]) }
  let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", env: "FOO", type: "string") }
  let(:bar) { instance_double(Unfig::ParamConfig, name: "bar", env: "BAR", type: "boolean") }
  let(:baz) { instance_double(Unfig::ParamConfig, name: "baz", env: "BAZ", type: "integer") }
  let(:bam) { instance_double(Unfig::ParamConfig, name: "bam", env: "BAM", type: "float") }

  describe "#read" do
    subject(:read) { env_loader.read }

    context "when none of the variables are supplied" do
      let(:env) { {} }
      it { is_expected.to eq({}) }
    end

    context "when a string is supplied" do
      let(:env) { {"FOO" => "hello"} }
      it { is_expected.to eq({"foo" => "hello"}) }
    end

    context "when a boolean is supplied" do
      let(:env) { {"BAR" => "true"} }
      it { is_expected.to eq({"bar" => true}) }

      context "as a falsey value" do
        let(:env) { {"BAR" => "n"} }
        it { is_expected.to eq({"bar" => false}) }
      end

      context "with a non-boolean string" do
        let(:env) { {"BAR" => "maybe"} }

        it "raises InvalidBooleanText" do
          expect { read }.to raise_error(
            described_class::InvalidBooleanText,
            "ENV['BAR'] had unexpected content for a boolean: 'maybe'"
          )
        end
      end
    end

    context "when an integer is supplied" do
      let(:env) { {"BAZ" => supplied} }
      let(:supplied) { "5678" }
      it { is_expected.to eq({"baz" => 5678}) }

      context "when a negative integer is supplied" do
        let(:supplied) { "-5678" }
        it { is_expected.to eq({"baz" => -5678}) }
      end

      context "when a space-padded integer is supplied" do
        let(:supplied) { "  588 \n" }
        it { is_expected.to eq({"baz" => 588}) }
      end

      context "but the value is not an integer" do
        let(:supplied) { "hello" }

        it "raises InvalidIntegerText" do
          expect { read }.to raise_error(
            described_class::InvalidIntegerText,
            "ENV['BAZ'] had unexpected content for an integer: 'hello'"
          )
        end
      end
    end

    context "when a float is supplied" do
      let(:env) { {"BAM" => supplied} }
      let(:supplied) { "1.5" }
      it { is_expected.to include("bam" => be_within(0.0001).of(1.5)) }

      context "and it's negative" do
        let(:supplied) { "-500.2" }
        it { is_expected.to include("bam" => be_within(0.0001).of(-500.2)) }
      end

      context "and it is only an integer" do
        let(:supplied) { "-5" }
        it { is_expected.to include("bam" => be_within(0.0001).of(-5.0)) }
      end

      context "but the value is not a float" do
        let(:supplied) { "hello" }

        it "raises InvalidFloatingPointText" do
          expect { read }.to raise_error(
            described_class::InvalidFloatingPointText,
            "ENV['BAM'] had unexpected content for a float: 'hello'"
          )
        end
      end
    end

    context "when the type is unrecognized" do
      let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", env: "FOO", type: "hash") }
      let(:env) { {"FOO" => "true"} }

      it "raises Invalid" do
        expect { read }.to raise_error(Unfig::Invalid, /does not know how to handle/)
      end
    end
  end
end
