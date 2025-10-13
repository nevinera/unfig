RSpec.describe Unfig::FileLoader do
  subject(:file_loader) { described_class.new(params:, path: "/foo/bar.yml") }

  let(:params) { instance_double(Unfig::ParamsConfig, params: [foo, bar, baz, bam]) }
  let(:all) { ["short", "long", "env", "file"] }
  let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", enabled: all, multi?: false, type: "string") }
  let(:bar) { instance_double(Unfig::ParamConfig, name: "bar", enabled: all, multi?: false, type: "boolean") }
  let(:baz) { instance_double(Unfig::ParamConfig, name: "baz", enabled: all, multi?: true, type: "integer") }
  let(:bam) { instance_double(Unfig::ParamConfig, name: "bam", enabled: all, multi?: false, type: "float") }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("/foo/bar.yml").and_return(yaml)
  end

  describe "#read" do
    subject(:read) { file_loader.read }

    context "when none of the params are set in the file" do
      let(:yaml) { "{}" }
      it { is_expected.to eq({}) }
    end

    context "when several parameters are supplied" do
      let(:yaml) do
        <<~YAML
          ---
          foo: hi
          bar: true
          baz: [1, 3, 5]
          bam: 1.5
        YAML
      end

      it { is_expected.to eq({"foo" => "hi", "bar" => true, "baz" => [1, 3, 5], "bam" => 1.5}) }

      context "but foo is not enabled for 'file'" do
        before { allow(foo).to receive(:enabled).and_return(["short", "long", "env"]) }

        it { is_expected.to eq({"bar" => true, "baz" => [1, 3, 5], "bam" => 1.5}) }
      end
    end

    context "when a multi-valued variable is supplied as if it were not multi-valued" do
      let(:yaml) do
        <<~YAML
          ---
          foo: hi
          bar: true
          baz: 44
          bam: 1.5
        YAML
      end

      it { is_expected.to eq({"foo" => "hi", "bar" => true, "baz" => 44, "bam" => 1.5}) }
    end

    context "when a string parameter is supplied incorrectly" do
      let(:yaml) { "{foo: 5}" }

      it "raises InvalidYamlValue" do
        expect { read }.to raise_error(Unfig::InvalidYamlValue, /expected a string for foo, but got Integer/)
      end
    end

    context "when a boolean parameter is supplied incorrectly" do
      let(:yaml) { "{bar: maybe}" }

      it "raises InvalidYamlValue" do
        expect { read }.to raise_error(Unfig::InvalidYamlValue, /expected a boolean for bar, but got String/)
      end
    end

    context "when an integer parameter is supplied incorrectly" do
      let(:yaml) { "{baz: 1.6}" }

      it "raises InvalidYamlValue" do
        expect { read }.to raise_error(Unfig::InvalidYamlValue, /expected an integer for baz, but got Float/)
      end
    end

    context "when a float parameter is supplied incorrectly" do
      let(:yaml) { "{bam: true}" }

      it "raises InvalidYamlValue" do
        expect { read }.to raise_error(Unfig::InvalidYamlValue, /expected a float for bam, but got TrueClass/)
      end
    end

    context "when the type is not recognized" do
      let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", enabled: all, multi?: false, type: "hash") }
      let(:yaml) { "{foo: bar}" }

      it "raises Invalid" do
        expect { read }.to raise_error(Unfig::Invalid, /does not know how to handle .* 'hash'/)
      end
    end
  end
end
