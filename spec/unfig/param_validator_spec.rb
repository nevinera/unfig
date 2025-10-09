RSpec.describe Unfig::ParamValidator do
  subject(:validator) { described_class.new(supplied_name, data) }

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

  describe "#validate!" do
    subject(:validate!) { validator.validate! }

    def self.it_is_valid
      it "is valid" do
        expect { validate! }.not_to raise_error
      end
    end

    def self.it_is_invalid_with(matcher)
      it "is appropriately invalid" do
        expect { validate! }.to raise_error(Unfig::Invalid, matcher)
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
        it_is_invalid_with(/must be supplied$/)
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
        it_is_invalid_with(/Type was not supplied/)
      end

      context "when supplied with a non-string value" do
        let(:type) { :boolean }
        it_is_invalid_with(/Type must be supplied as a string/)
      end

      context "when supplied with an unrecognized type" do
        let(:type) { "hash" }
        it_is_invalid_with(/Type not recognized/)
      end
    end

    describe "on multi" do
      let(:default) { nil }

      context "when not a boolean" do
        let(:multi) { 5 }
        it_is_invalid_with(/Multi must be a boolean/)
      end

      context "when nil" do
        let(:multi) { nil }
        it_is_invalid_with(/Multi must be a boolean/)
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
        it_is_invalid_with(/Enabled must be an array/)
      end

      context "when enabled is empty" do
        let(:enabled) { [] }
        it_is_invalid_with(/Enabled must not be empty/)
      end

      context "when enabled contains unexpected values" do
        let(:enabled) { ["long", "short", "medium", "file", "spoken"] }
        it_is_invalid_with(/Enabled includes unrecognized values: medium, spoken/)
      end
    end

    describe "on default" do
      context "when not supplied" do
        let(:data) { base_data.except(:default) }
        it_is_invalid_with(/Default not supplied/)
      end

      context "when multi-valued" do
        let(:type) { "boolean" }
        let(:multi) { true }

        context "and the value is not an array" do
          let(:default) { true }
          it_is_invalid_with(/Multi-valued, but default is not an Array/)
        end

        context "and the value is nil" do
          let(:default) { nil }
          it_is_valid
        end

        context "and one of the values is not the right type" do
          let(:default) { [true, true, false, 5, false] }
          it_is_invalid_with(/Default includes non-boolean values/)
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
            it_is_invalid_with(/Default is not a boolean/)
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
            it_is_invalid_with(/Default is not a string/)
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
            it_is_invalid_with(/Default is not a integer/)
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
            it_is_invalid_with(/Default is not a float/)
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
        it_is_invalid_with(/Long flag is not a string/)
      end

      context "when including whitespace" do
        let(:long) { "my long" }
        it_is_invalid_with(/Long flag includes whitespace/)
      end
    end

    describe "on long" do
      context "when not supplied" do
        let(:data) { base_data.except(:long) }
        it_is_valid
      end

      context "when not a string" do
        let(:long) { :my_long }
        it_is_invalid_with(/Long flag is not a string/)
      end

      context "when including whitespace" do
        let(:long) { "my long" }
        it_is_invalid_with(/Long flag includes whitespace/)
      end

      context "when too long" do
        let(:long) { "x" * 65 }
        it_is_invalid_with(/Long flag is over 64 characters/)
      end
    end

    describe "on short" do
      context "when not supplied" do
        let(:data) { base_data.except(:short) }
        it_is_valid
      end

      context "when not a string" do
        let(:short) { :a }
        it_is_invalid_with(/Short flag is not a string/)
      end

      context "when not a supported character" do
        let(:short) { "?" }
        it_is_invalid_with(/Short flag must be a single letter or digit/)
      end

      context "when too long" do
        let(:short) { "xx" }
        it_is_invalid_with(/Short flag must be a single letter or digit/)
      end
    end

    describe "on env" do
      context "when not supplied" do
        let(:data) { base_data.except(:env) }
        it_is_valid
      end

      context "when not a string" do
        let(:env) { :my_env }
        it_is_invalid_with(/ENV name is not a string/)
      end

      context "when including whitespace" do
        let(:env) { "my env" }
        it_is_invalid_with(/ENV name may only contain alphanumerics and underscores/)
      end

      context "when not starting with a letter" do
        let(:env) { "0FOO" }
        it_is_invalid_with(/ENV name must begin with a letter/)
      end

      context "when too long" do
        let(:env) { "x" * 65 }
        it_is_invalid_with(/ENV name is over 64 characters/)
      end
    end
  end
end
