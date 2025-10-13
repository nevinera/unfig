RSpec.describe Unfig::EnvReader do
  subject(:env_reader) { described_class.new(param:, env:) }

  let(:param) { instance_double(Unfig::ParamConfig, name: "foo", env: "FOO", multi?: multi, type:) }
  let(:multi) { false }
  let(:type) { "string" }

  describe "#supplied?" do
    subject(:supplied?) { env_reader.supplied? }

    context "when the parameter takes a single value" do
      let(:multi) { false }

      context "and the key is not supplied" do
        let(:env) { {} }
        it { is_expected.to be_falsey }
      end

      context "and the key is supplied" do
        let(:env) { {"FOO" => ""} }
        it { is_expected.to be_truthy }
      end
    end

    context "when the parameter takes multiple values" do
      let(:multi) { true }

      context "when none of the relevant envs are supplied" do
        let(:env) { {} }
        it { is_expected.to be_falsey }
      end

      context "when the singular env is supplied" do
        let(:env) { {"FOO" => "yes"} }
        it { is_expected.to be_truthy }
      end

      context "when some of the number envs are supplied" do
        let(:env) { {"FOO_1" => "yes", "FOO_4" => "maybe"} }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe "#value" do
    subject(:value) { env_reader.value }

    context "when single-valued" do
      let(:multi) { false }

      context "when a value is not supplied" do
        let(:env) { {} }
        it { is_expected.to be_nil }
      end

      context "when type is string" do
        let(:type) { "string" }
        let(:env) { {"FOO" => "hello"} }
        it { is_expected.to eq("hello") }
      end

      context "when type is boolean" do
        let(:type) { "boolean" }

        context "and a truthy value is supplied" do
          let(:env) { {"FOO" => "true"} }
          it { is_expected.to eq(true) }
        end

        context "and a falsey value is supplied" do
          let(:env) { {"FOO" => "n"} }
          it { is_expected.to eq(false) }
        end

        context "and a non-boolean string is supplied" do
          let(:env) { {"FOO" => "maybe"} }

          it "raises InvalidBooleanText" do
            expect { value }.to raise_error(
              Unfig::InvalidBooleanText,
              "ENV['FOO'] had unexpected content for a boolean: 'maybe'"
            )
          end
        end
      end

      context "when type is integer" do
        let(:type) { "integer" }

        context "when an integer is supplied" do
          let(:env) { {"FOO" => "5678"} }
          it { is_expected.to eq(5678) }
        end

        context "when a negative integer is supplied" do
          let(:env) { {"FOO" => "-5678"} }
          it { is_expected.to eq(-5678) }
        end

        context "when a space-padded integer is supplied" do
          let(:env) { {"FOO" => "  5678 \n\t"} }
          it { is_expected.to eq(5678) }
        end

        context "when the value is not an integer" do
          let(:env) { {"FOO" => "hello"} }

          it "raises InvalidIntegerText" do
            expect { value }.to raise_error(
              Unfig::InvalidIntegerText,
              "ENV['FOO'] had unexpected content for an integer: 'hello'"
            )
          end
        end
      end

      context "when type is float" do
        let(:type) { "float" }

        context "and a float is supplied" do
          let(:env) { {"FOO" => "1.5"} }
          it { is_expected.to be_within(0.001).of(1.5) }

          context "but padded with some whitespace" do
            let(:env) { {"FOO" => "  1.5  \t"} }
            it { is_expected.to be_within(0.001).of(1.5) }
          end
        end

        context "and an integer is supplied" do
          let(:env) { {"FOO" => "15"} }
          it { is_expected.to be_a(Float) }
          it { is_expected.to be_within(0.001).of(15) }
        end

        context "and it is negative" do
          let(:env) { {"FOO" => "-1.5"} }
          it { is_expected.to be_within(0.001).of(-1.5) }
        end

        context "but it is not a float" do
          let(:env) { {"FOO" => "hello"} }

          it "raises InvalidFloatingPointText" do
            expect { value }.to raise_error(
              Unfig::InvalidFloatingPointText,
              "ENV['FOO'] had unexpected content for a float: 'hello'"
            )
          end
        end
      end

      # We shouldn't actually get this, since the ParamConfig validator blocks this case also.
      context "when type is unrecognized" do
        let(:type) { "hash" }
        let(:env) { {"FOO" => "?"} }

        it "raises Invalid" do
          expect { value }.to raise_error(Unfig::Invalid, /does not know.*parameter type 'hash'/)
        end
      end
    end

    context "when multi-valued" do
      let(:multi) { true }

      context "when none are supplied" do
        let(:env) { {} }
        it { is_expected.to eq([]) }
      end

      context "when single-env is supplied" do
        let(:env) { {"FOO" => "hello"} }
        it { is_expected.to contain_exactly("hello") }
      end

      context "when multi-envs are supplied" do
        let(:env) { {"FOO_0" => "one", "FOO_4" => "two", "FOO_9" => "three"} }
        it { is_expected.to eq(["one", "two", "three"]) }
      end

      context "when both single- AND multi-envs are supplied" do
        let(:env) { {"FOO_8" => "f8", "FOO" => "f"} }
        it { is_expected.to eq(["f", "f8"]) }
      end
    end
  end
end
