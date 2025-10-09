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

  context "when not valid" do
    let(:supplied_name) { "foo bar" }

    it "fails to instantiate" do
      expect { pc }.to raise_error(Unfig::Invalid)
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
