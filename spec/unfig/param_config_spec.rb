RSpec.describe Unfig::ParamConfig do
  subject(:pc) { described_class.new(supplied_name, data) }

  let(:supplied_name) { "foo" }
  let(:base) do
    {
      "description" => "Foo is for foo",
      "type" => "boolean",
      "default" => true,
      "env" => "FOO",
      "long" => "foo",
      "short" => "f"
    }
  end
  let(:data) { base }

  describe ".load" do
    subject(:loaded) { described_class.load(params_data) }

    let(:params_data) { {"foo" => foo_data, "bar" => bar_data} }
    let(:foo_data) { {description: "My Foo", type: "boolean", default: false, env: "FOO"} }
    let(:bar_data) { {description: "My Bar", type: "integer", default: nil, short: "a", long: "bar-bar"} }

    it { is_expected.to have_exactly(2).items }

    it "produces an array of ParamConfigs" do
      expect(loaded).to all(be_a(described_class))
    end

    it "produces the expected configs", :aggregate_failures do
      foo = loaded.detect { |c| c.name == "foo" }
      expect(foo).to have_attributes(
        type: :boolean,
        default: false,
        long_supplied?: false,
        long: nil,
        short_supplied?: false,
        short: nil,
        env_supplied?: true,
        env: "FOO"
      )

      bar = loaded.detect { |c| c.name == "bar" }
      expect(bar).to have_attributes(
        type: :integer,
        default: nil,
        long_supplied?: true,
        long: "bar-bar",
        short_supplied?: true,
        short: "a",
        env_supplied?: false,
        env: nil
      )
    end
  end

  describe "#name" do
    subject(:name) { pc.name }
    it { is_expected.to eq("foo") }

    context "when the name is supplied as a symbol" do
      let(:supplied_name) { :foo }
      it { is_expected.to eq("foo") }
    end

    context "when name has unexpected characters in it" do
      let(:supplied_name) { "foo-bar" }

      it "raises Invalid" do
        expect { name }.to raise_error(described_class::Invalid, /'foo-bar' may contain only/)
      end
    end

    context "when name is too long" do
      let(:supplied_name) { "x" * 129 }

      it "raises Invalid" do
        expect { name }.to raise_error(described_class::Invalid, /xxxx' contains more than 128 characters/)
      end
    end
  end

  describe "#description" do
    subject(:description) { pc.description }
    it { is_expected.to eq("Foo is for foo") }

    context "when description is supplied as a symbol" do
      let(:data) { base.merge("description" => :foo_desc) }
      it { is_expected.to eq("foo_desc") }
    end

    context "when description is supplied with a string key" do
      let(:data) { base.except("description").merge(description: "foo desc") }
      it { is_expected.to eq("foo desc") }
    end

    context "when description is supplied as nil" do
      let(:data) { base.merge("description" => nil) }

      it "raises Invalid" do
        expect { description }
          .to raise_error(described_class::Invalid, /description for foo must not be blank/i)
      end
    end

    context "when description is supplied with a blank string" do
      let(:data) { base.merge("description" => "  ") }

      it "raises Invalid" do
        expect { description }
          .to raise_error(described_class::Invalid, /description for foo must not be blank/i)
      end
    end
  end

  describe "#type" do
    subject(:type) { pc.type }
    it { is_expected.to eq(:boolean) }

    context "when supplied as a symbol" do
      let(:data) { base.merge(type: :boolean) }
      it { is_expected.to eq(:boolean) }
    end

    context "when supplied with a symbol key" do
      let(:data) { base.except("type").merge(type: "boolean") }
      it { is_expected.to eq(:boolean) }
    end

    context "when supplied with an unrecognized type" do
      let(:data) { base.merge("type" => "hash") }

      it "raises Invalid" do
        expect { type }.to raise_error(described_class::Invalid, /for foo is not recognized/i)
      end
    end
  end

  describe "#default" do
    subject(:default) { pc.default }
    it { is_expected.to eq(true) }

    def self.it_accepts(desc, supplied, produced, produced_name = nil)
      context "when supplied with #{desc}" do
        let(:data) { base.merge("type" => type, "default" => supplied) }

        it "produces #{produced_name || produced} for #{supplied}" do
          expect(pc.default).to eq(produced)
        end
      end
    end

    def self.it_raises(desc, supplied, message_matcher)
      context "when supplied with #{desc}" do
        let(:data) { base.merge("type" => type, "default" => supplied) }

        it "raises Invalid appropriately" do
          expect { pc.default }.to raise_error(described_class::Invalid, message_matcher)
        end
      end
    end

    context "when type is :boolean" do
      let(:type) { "boolean" }

      it_accepts "nil", nil, nil, "nil"
      it_accepts "true", true, true
      it_accepts "false", false, false
      it_raises "a string", "string-foo", /not a boolean/i
      it_raises "a number", 1.5, /not a boolean/i
    end

    context "when type is :string" do
      let(:type) { "string" }

      it_accepts "nil", nil, nil, "nil"
      it_accepts "an empty string", "", ""
      it_accepts "a non-empty string", "foo-bar", "foo-bar"
      it_raises "a boolean", false, /not a string/
      it_raises "a number", 4, /not a string/
    end

    context "when type is :integer" do
      let(:type) { "integer" }

      it_accepts "nil", nil, nil, "nil"
      it_accepts "0", 0, 0
      it_accepts "1024", 1024, 1024
      it_accepts "-5", -5, -5
      it_raises "a boolean", true, /not an integer/
      it_raises "a string", "foo", /not an integer/
      it_raises "a float", 1.6, /not an integer/
    end

    context "when type is :float" do
      let(:type) { "float" }

      it_accepts "nil", nil, nil, "nil"
      it_accepts "0", 0, 0
      it_accepts "0.5", 0.5, 0.5
      it_accepts "-0.75", -0.75, -0.75
      it_accepts "an integer", 1024, 1024, "the integer"
      it_raises "a boolean", true, /not a float/
      it_raises "a string", "foo", /not a float/
    end
  end

  describe "#long_supplied?" do
    subject(:long_supplied?) { pc.long_supplied? }

    context "when it is supplied" do
      let(:data) { base.merge("long" => "foo") }
      it { is_expected.to be_truthy }
    end

    context "when it is not supplied" do
      let(:data) { base.except("long") }
      it { is_expected.to be_falsey }
    end

    context "when it supplied as nil" do
      let(:data) { base.merge("long" => nil) }
      it { is_expected.to be_truthy }
    end
  end

  describe "#long" do
    subject(:long) { pc.long }

    context "when not supplied" do
      let(:data) { base.except("long") }
      it { is_expected.to be_nil }
    end

    context "when supplied as a number" do
      let(:data) { base.merge("long" => 55) }

      it "raises Invalid" do
        expect { long }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as an array" do
      let(:data) { base.merge("long" => ["foo", "bar"]) }

      it "raises Invalid" do
        expect { long }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as a string" do
      let(:data) { base.merge("long" => "a-string") }
      it { is_expected.to eq("a-string") }

      context "which includes whitespace" do
        let(:data) { base.merge("long" => "a string") }

        it "raises invalid" do
          expect { long }.to raise_error(described_class::Invalid, /for foo includes whitespace/i)
        end
      end
    end
  end

  describe "#short_supplied?" do
    subject(:short_supplied?) { pc.short_supplied? }

    context "when it is supplied" do
      let(:data) { base.merge("short" => "foo") }
      it { is_expected.to be_truthy }
    end

    context "when it is not supplied" do
      let(:data) { base.except("short") }
      it { is_expected.to be_falsey }
    end

    context "when it supplied as nil" do
      let(:data) { base.merge("short" => nil) }
      it { is_expected.to be_truthy }
    end
  end

  describe "#short" do
    subject(:short) { pc.short }

    context "when not supplied" do
      let(:data) { base.except("short") }
      it { is_expected.to be_nil }
    end

    context "when supplied as a number" do
      let(:data) { base.merge("short" => 5) }

      it "raises Invalid" do
        expect { short }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as an array" do
      let(:data) { base.merge("short" => ["X", "v"]) }

      it "raises Invalid" do
        expect { short }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as a string" do
      let(:data) { base.merge("short" => "a") }
      it { is_expected.to eq("a") }

      context "which is not a single character" do
        let(:data) { base.merge("short" => "foo") }

        it "raises invalid" do
          expect { short }.to raise_error(described_class::Invalid, /for foo must be/i)
        end
      end

      context "which contains a not-allowed value" do
        let(:data) { base.merge("short" => "?") }

        it "raises Invalid" do
          expect { short }.to raise_error(described_class::Invalid, /for foo must be/i)
        end
      end
    end
  end

  describe "#env_supplied?" do
    subject(:env_supplied?) { pc.env_supplied? }

    context "when it is supplied" do
      let(:data) { base.merge("env" => "foo") }
      it { is_expected.to be_truthy }
    end

    context "when it is not supplied" do
      let(:data) { base.except("env") }
      it { is_expected.to be_falsey }
    end

    context "when it supplied as nil" do
      let(:data) { base.merge("env" => nil) }
      it { is_expected.to be_truthy }
    end
  end

  describe "#env" do
    subject(:env) { pc.env }

    context "when not supplied" do
      let(:data) { base.except("env") }
      it { is_expected.to be_nil }
    end

    context "when supplied as a number" do
      let(:data) { base.merge("env" => 5) }

      it "raises Invalid" do
        expect { env }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as an array" do
      let(:data) { base.merge("env" => ["X", "v"]) }

      it "raises Invalid" do
        expect { env }.to raise_error(described_class::Invalid, /for foo is not a string/i)
      end
    end

    context "when supplied as a string" do
      let(:data) { base.merge("env" => "FOO2") }
      it { is_expected.to eq("FOO2") }

      context "which contains a not-allowed character" do
        let(:data) { base.merge("env" => "FOO?") }

        it "raises Invalid" do
          expect { env }.to raise_error(described_class::Invalid, /for foo may only contain/i)
        end
      end

      context "which starts with a non-alphabetic" do
        let(:data) { base.merge("env" => "2FOO") }

        it "raises Invalid" do
          expect { env }.to raise_error(described_class::Invalid, /for foo must begin with a letter/i)
        end
      end
    end
  end
end
