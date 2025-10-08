RSpec.describe Unfig::ParamConfig do
  subject(:pc) { described_class.new(supplied_name, data) }

  let(:supplied_name) { "foo" }
  let(:base_data) { {description:, type:, enabled:, default:, multi:, env:, long:, short:} }
  let(:data) { base_data }
  let(:description) { "Foo is for foo" }
  let(:type) { "boolean" }
  let(:enabled) { ["long", "short", "file"] }
  let(:default) { true }
  let(:multi) { false }
  let(:env) { "FOO_ENV" }
  let(:long) { "foo-foo" }
  let(:short) { "o" }

  describe "validations" do
    subject(:instantiation) { described_class.new(supplied_name, data) }

    def self.it_is_valid
      it "is valid" do
        expect { instantiation }.not_to raise_error
      end
    end

    def self.it_is_invalid_with(matcher)
      it "is appropriately invalid" do
        expect { instantiation }.to raise_error(described_class::Invalid, matcher)
      end
    end

    it_is_valid

    describe "on name" do
      context "when supplied as a symbol" do
        let(:supplied_name) { :foo }
        it_is_invalid_with(/is not a string/)
      end

      context "when including unexpected characters" do
        let(:supplied_name) { "foo?" }
        it_is_invalid_with(/may contain only/)
      end

      context "when too long" do
        let(:supplied_name) { "x" * 65 }
        it_is_invalid_with(/contains more than 64/)
      end
    end

    describe "on description" do
      context "when not supplied" do
        let(:data) { base_data.except(:description) }
        it_is_invalid_with(/must be supplied for/)
      end

      context "when not a string" do
        let(:description) { :foo_is_foo }
        it_is_invalid_with(/must be supplied as a string/)
      end

      context "when blank" do
        let(:description) { "    " }
        it_is_invalid_with(/must not be blank/)
      end

      context "when including newlines" do
        let(:description) { "Foo\nis\nFoo" }
        it_is_invalid_with(/may not include newlines/)
      end
    end

    describe "on type" do
      context "when not supplied" do
        let(:data) { base_data.except(:type) }
        it_is_invalid_with(/Type for foo was not supplied/)
      end

      context "when supplied with a non-string value" do
        let(:type) { :boolean }
        it_is_invalid_with(/Type for foo must be supplied as a string/)
      end

      context "when supplied with an unrecognized type" do
        let(:type) { "hash" }
        it_is_invalid_with(/Type supplied for foo is not recognized/)
      end
    end

    describe "on multi" do
      let(:default) { nil }

      context "when not a boolean" do
        let(:multi) { 5 }
        it_is_invalid_with(/non-boolean for 'multi'/)
      end

      context "when nil" do
        let(:multi) { nil }
        it_is_invalid_with(/non-boolean for 'multi'/)
      end

      context "when true" do
        let(:multi) { true }
        it_is_valid
      end
    end

    describe "on enabled" do
      context "when enabled includes fewer values" do
        let(:enabled) { ["short", "file"] }
        it_is_valid
      end

      context "when enabled is not an array" do
        let(:enabled) { true }
        it_is_invalid_with(/non-array supplied for 'enabled'/)
      end

      context "when enabled is empty" do
        let(:enabled) { [] }
        it_is_invalid_with(/has no input methods enabled/)
      end

      context "when enabled contains unexpected values" do
        let(:enabled) { ["long", "short", "medium", "file", "spoken"] }
        it_is_invalid_with(/unrecognized 'enabled' values: medium, spoken/)
      end
    end

    describe "on default" do
      context "when not supplied" do
        let(:data) { base_data.except(:default) }
        it_is_invalid_with(/Default not supplied for foo/)
      end

      context "when multi-valued" do
        let(:type) { "boolean" }
        let(:multi) { true }

        context "and the value is not an array" do
          let(:default) { true }
          it_is_invalid_with(/Default for multi-valued foo is not an array/)
        end

        context "and the value is nil" do
          let(:default) { nil }
          it_is_valid
        end

        context "and one of the values is not the right type" do
          let(:default) { [true, true, false, 5, false] }
          it_is_invalid_with(/Default for foo includes non-boolean values/)
        end
      end

      context "when not multi-valued" do
        let(:multi) { false }

        context "when type is boolean" do
          let(:type) { "boolean" }

          context "and value is nil" do
            let(:default) { nil }
            it_is_valid
          end

          context "and value is not boolean" do
            let(:default) { 5 }
            it_is_invalid_with(/Default for foo is not a boolean/)
          end

          context "and value is boolean" do
            let(:default) { true }
            it_is_valid
          end
        end

        context "when type is string" do
          let(:type) { "string" }

          context "and value is nil" do
            let(:default) { nil }
            it_is_valid
          end

          context "and value is not a string" do
            let(:default) { 5 }
            it_is_invalid_with(/Default for foo is not a string/)
          end

          context "and value is a string" do
            let(:default) { "hello" }
            it_is_valid
          end
        end

        context "when type is integer" do
          let(:type) { "integer" }

          context "and value is nil" do
            let(:default) { nil }
            it_is_valid
          end

          context "and value is not an integer" do
            let(:default) { 6.4 }
            it_is_invalid_with(/Default for foo is not a integer/)
          end

          context "and value is an integer" do
            let(:default) { 6 }
            it_is_valid
          end
        end

        context "when type is float" do
          let(:type) { "float" }

          context "and value is nil" do
            let(:default) { nil }
            it_is_valid
          end

          context "and value is not a float" do
            let(:default) { true }
            it_is_invalid_with(/Default for foo is not a float/)
          end

          context "and value is an integer" do
            let(:default) { 6 }
            it_is_valid
          end

          context "and value is a float" do
            let(:default) { 6.5 }
            it_is_valid
          end
        end
      end
    end

    describe "on long" do
      context "when not supplied" do
        let(:data) { base_data.except(:long) }
        it_is_valid
      end

      context "when not a string" do
        let(:long) { :my_long }
        it_is_invalid_with(/Long flag.*is not a string/)
      end

      context "when including whitespace" do
        let(:long) { "my long" }
        it_is_invalid_with(/Long flag.*foo includes whitespace/)
      end
    end

    describe "on long" do
      context "when not supplied" do
        let(:data) { base_data.except(:long) }
        it_is_valid
      end

      context "when not a string" do
        let(:long) { :my_long }
        it_is_invalid_with(/Long flag.*is not a string/)
      end

      context "when including whitespace" do
        let(:long) { "my long" }
        it_is_invalid_with(/Long flag.*foo includes whitespace/)
      end

      context "when too long" do
        let(:long) { "x" * 65 }
        it_is_invalid_with(/Long flag for foo is over 64 characters/)
      end
    end

    describe "on short" do
      context "when not supplied" do
        let(:data) { base_data.except(:short) }
        it_is_valid
      end

      context "when not a string" do
        let(:short) { :a }
        it_is_invalid_with(/Short flag.*is not a string/)
      end

      context "when not a supported character" do
        let(:short) { "?" }
        it_is_invalid_with(/Short flag.*foo.*single letter or digit/)
      end

      context "when too long" do
        let(:short) { "xx" }
        it_is_invalid_with(/Short flag.*foo.*single/)
      end
    end

    describe "on env" do
      context "when not supplied" do
        let(:data) { base_data.except(:env) }
        it_is_valid
      end

      context "when not a string" do
        let(:env) { :my_env }
        it_is_invalid_with(/ENV name.*is not a string/)
      end

      context "when including whitespace" do
        let(:env) { "my env" }
        it_is_invalid_with(/ENV name.*may only contain/)
      end

      context "when not starting with a letter" do
        let(:env) { "0FOO" }
        it_is_invalid_with(/ENV name.*must begin with a letter/)
      end

      context "when too long" do
        let(:env) { "x" * 65 }
        it_is_invalid_with(/ENV name for foo is over 64 characters/)
      end
    end
  end

  describe "#enabled" do
    subject { pc.enabled }

    context "when not supplied" do
      let(:data) { base_data.except(:enabled) }
      it { is_expected.to match_array(described_class::KNOWN_ENABLED_VALUES) }
    end

    context "when supplied with a subset" do
      let(:enabled) { ["long", "short"] }
      it { is_expected.to contain_exactly("long", "short") }
    end
  end

  describe "#long" do
    subject { pc.long }

    context "when not supplied" do
      let(:data) { base_data.except(:long) }
      it { is_expected.to eq("foo") }

      context "and the name includes underscores" do
        let(:supplied_name) { "foo_bar" }
        it { is_expected.to eq("foo-bar") }
      end
    end

    context "when supplied as a string" do
      let(:long) { "a-string" }
      it { is_expected.to eq("a-string") }
    end
  end

  describe "#short" do
    subject { pc.short }

    context "when not supplied" do
      let(:data) { base_data.except(:short) }
      it { is_expected.to eq("f") }
    end

    context "when supplied as a string" do
      let(:short) { "a" }
      it { is_expected.to eq("a") }
    end
  end

  describe "#env" do
    subject { pc.env }

    context "when not supplied" do
      let(:data) { base_data.except(:env) }
      it { is_expected.to eq("FOO") }

      context "and name includes underscores" do
        let(:supplied_name) { "foo_bar" }
        it { is_expected.to eq("FOO_BAR") }
      end
    end

    context "when supplied as a string" do
      let(:env) { "FOO2" }
      it { is_expected.to eq("FOO2") }
    end
  end
end
