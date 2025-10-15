require "open3"

RSpec.describe Unfig do
  describe ".load_options" do
    subject(:load_options) { described_class.load_options(values:, format:, banner:, env:, argv:, config:) }

    let(:inputs) { {} }
    let(:format) { :hash }
    let(:banner) { nil }
    let(:argv) { ["--foo"] }
    let(:env) { {"BAZ" => "59"} }
    let(:config) { "/tmp/config.yml" }

    let(:values) do
      {
        foo: {type: "boolean", default: false, description: "The Foo"},
        bar: {type: "string", default: [], description: "The Bar", multi: true},
        baz: {type: "integer", default: 21, description: "The Baz", enabled: ["long", "env"], short: "r"}
      }
    end

    let(:config_yaml) { "{baz: 56, foo: false, bar: ['yeah', 'nope']}" }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(config).and_return(config_yaml)
    end

    it "produces the expected result" do
      expect(load_options).to eq({foo: true, bar: ["yeah", "nope"], baz: 59})
    end
  end

  # Note that these do not count toward coverage (as they are running the tested code
  # in another process)
  describe "integration tests" do
    let(:script_path) { File.expand_path("../fixtures/test_script", __FILE__) }

    context "with nothing supplied" do
      let(:env) { {} }

      it "produces the expected output" do
        stdout, stderr, status = Open3.capture3(env, script_path)
        expect(stderr).to be_empty
        expect(status).to be_success
        expect(stdout).to eq(<<~OUTPUT)
          parsed configuration:
          ---------------------

          verbose: false
          color: true
          voltron: ["arm","leg","head"]
          size: 56.4
          count: 1
        OUTPUT
      end
    end

    context "with several options passed in and an env set" do
      let(:env) { {"COUNT" => "5"} }

      it "produces the expected output" do
        stdout, stderr, status = Open3.capture3(env, script_path, "--no-color", "--voltron=face", "-v", "--voltron=knee")
        expect(stderr).to be_empty
        expect(status).to be_success
        expect(stdout).to eq(<<~OUTPUT)
          parsed configuration:
          ---------------------

          verbose: true
          color: false
          voltron: ["face","knee"]
          size: 56.4
          count: 5
        OUTPUT
      end
    end
  end
end
