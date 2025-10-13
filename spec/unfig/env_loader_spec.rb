RSpec.describe Unfig::EnvLoader do
  subject(:env_loader) { described_class.new(params:, env:) }

  let(:params) { instance_double(Unfig::ParamsConfig, params: [foo, bar, baz, bam]) }
  let(:all) { ["short", "long", "env", "file"] }
  let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", env: "FOO", enabled: all, multi?: false, type: "string") }
  let(:bar) { instance_double(Unfig::ParamConfig, name: "bar", env: "BAR", enabled: all, multi?: false, type: "boolean") }
  let(:baz) { instance_double(Unfig::ParamConfig, name: "baz", env: "BAZ", enabled: all, multi?: true, type: "integer") }
  let(:bam) { instance_double(Unfig::ParamConfig, name: "bam", env: "BAM", enabled: all, multi?: false, type: "float") }

  describe "#read" do
    subject(:read) { env_loader.read }

    context "when none of the variables are supplied" do
      let(:env) { {} }
      it { is_expected.to eq({}) }
    end

    context "when several of the variables are supplied" do
      let(:env) { {"FOO" => "hi", "BAR" => "t", "BAZ" => "1", "BAZ_2" => "2", "BAM" => "1.5"} }
      it { is_expected.to eq({"foo" => "hi", "bar" => true, "baz" => [1, 2], "bam" => 1.5}) }

      context "but foo is _disabled_ for env" do
        before { allow(foo).to receive(:enabled).and_return(["short", "long", "file"]) }

        it { is_expected.to eq({"bar" => true, "baz" => [1, 2], "bam" => 1.5}) }
      end
    end
  end
end
