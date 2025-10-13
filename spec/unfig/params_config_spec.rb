RSpec.describe Unfig::ParamsConfig do
  subject(:config) { described_class.new(data) }

  let(:data) { {params: {foo: foo_config, bar: bar_config, baz: baz_config}} }
  let(:foo_config) { {description: "The Foo", type: "boolean", default: true} }
  let(:bar_config) { {description: "The Bar", type: "integer", default: 3} }
  let(:baz_config) { {description: "The Baz", type: "string", default: "yes", short: "z"} }

  context "when the supplied config is not a hash" do
    let(:data) { "hi" }

    it "raises Invalid" do
      expect { config }.to raise_error(Unfig::Invalid, /must be a Hash/)
    end
  end

  context "when the supplied config lacks a :params` key" do
    let(:data) { {test: "foo"} }

    it "raises Invalid" do
      expect { config }.to raise_error(Unfig::Invalid, /must supply/)
    end
  end

  context "when the supplied config has a non-Hash :params value" do
    let(:data) { {params: []} }

    it "raises Invalid" do
      expect { config }.to raise_error(Unfig::Invalid, /must supply/)
    end
  end

  describe "#banner" do
    subject(:banner) { config.banner }

    context "when no banner is supplied" do
      let(:data) { {params: {foo: foo_config, bar: bar_config, baz: baz_config}} }
      it { is_expected.to be_nil }
    end

    context "when a banner is supplied" do
      let(:data) { {banner: "This banner", params: {foo: foo_config, bar: bar_config, baz: baz_config}} }
      it { is_expected.to eq("This banner") }
    end
  end

  describe "#params" do
    subject(:params) { config.params }

    it "produces the expected ParamConfig objects", :aggregate_failures do
      expect(params.length).to eq(3)
      expect(params).to all(be_a(Unfig::ParamConfig))
      expect(params.map(&:name)).to contain_exactly("foo", "bar", "baz")
    end

    context "when two of the params have the same name" do
      let(:data) { {params: {:foo => foo_config, "foo" => bar_config, :baz => baz_config}} }

      it "raises Invalid" do
        expect { params }.to raise_error(Unfig::Invalid, /Duplicate parameter names: foo/)
      end
    end

    context "when two of the params have the same 'long' flag-name" do
      let(:foo_config) { {description: "The Foo", type: "boolean", long: "dup-long", default: true} }
      let(:bar_config) { {description: "The Bar", type: "integer", long: "dup-long", default: 3} }

      it "raises Invalid" do
        expect { params }.to raise_error(Unfig::Invalid, /Duplicate long-flags: dup-long/)
      end
    end

    context "when two of the params have the same 'short' flag" do
      let(:foo_config) { {description: "The Foo", type: "boolean", short: "x", default: true} }
      let(:bar_config) { {description: "The Bar", type: "integer", short: "x", default: 3} }

      it "raises Invalid" do
        expect { params }.to raise_error(Unfig::Invalid, /Duplicate short-flags: x/)
      end
    end

    context "when two of the params have the same env-name" do
      let(:foo_config) { {description: "The Foo", type: "boolean", env: "XX", default: true} }
      let(:bar_config) { {description: "The Bar", type: "integer", env: "XX", default: 3} }

      it "raises Invalid" do
        expect { params }.to raise_error(Unfig::Invalid, /Duplicate env-names: XX/)
      end
    end
  end
end
