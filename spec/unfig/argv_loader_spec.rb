RSpec.describe Unfig::ArgvLoader do
  subject(:argv_loader) { described_class.new(params:, argv:) }

  let(:params) { instance_double(Unfig::ParamsConfig, banner: "My Banner", params: [foo, bar, baz, bam]) }
  let(:all) { ["short", "long", "env", "file"] }
  let(:foo) { instance_double(Unfig::ParamConfig, name: "foo", enabled: all, multi?: false, type: "string", short: "f", long: "foo", description: "My Foo") }
  let(:bar) { instance_double(Unfig::ParamConfig, name: "bar", enabled: all, multi?: false, type: "boolean", short: "b", long: "bar", description: "My Bar") }
  let(:baz) { instance_double(Unfig::ParamConfig, name: "baz", enabled: all, multi?: true, type: "integer", short: "z", long: "baz", description: "My Baz") }
  let(:bam) { instance_double(Unfig::ParamConfig, name: "bam", enabled: all, multi?: false, type: "float", short: "m", long: "bam", description: "My Bam") }

  let(:argv) { [] }

  describe "#read" do
    subject(:read) { argv_loader.read }

    context "when no arguments are supplied" do
      let(:argv) { [] }
      it { is_expected.to eq({}) }
    end

    context "when '--help' is supplied" do
      let(:argv) { ["--help"] }

      it "writes the help text to stderr and returns nil", :aggregate_failures do
        expect do
          expect(read).to be_nil
        end.to output(/My Banner/).to_stderr
      end
    end

    context "when a non-multi argument is supplied more than once" do
      let(:argv) { ["--foo=aaa", "--foo=bbb"] }

      it "raises FlagError" do
        expect { read }.to raise_error(Unfig::FlagError, /more than once/)
      end
    end

    context "when a multi-argument is supplied more than once" do
      let(:argv) { ["--baz=5", "--baz=7", "--baz=9"] }
      it { is_expected.to eq({"baz" => [5, 7, 9]}) }
    end

    context "when a boolean is supplied" do
      context "when a short argument is supplied" do
        let(:argv) { ["-b"] }
        it { is_expected.to eq({"bar" => true}) }
      end

      context "when a long argument is supplied" do
        let(:argv) { ["--bar"] }
        it { is_expected.to eq({"bar" => true}) }
      end

      context "when a long argument is inverted" do
        let(:argv) { ["--no-bar"] }
        it { is_expected.to eq({"bar" => false}) }
      end

      context "when a long argument is supplied _with a value_" do
        let(:argv) { ["--bar=false"] }

        it "raises NeedlessArgument" do
          expect { read }.to raise_error(OptionParser::NeedlessArgument, /--bar=false/)
        end
      end
    end

    context "when a string is supplied" do
      context "via short argument" do
        let(:argv) { ["-fHello"] }
        it { is_expected.to eq({"foo" => "Hello"}) }
      end

      context "via long argument" do
        let(:argv) { ["--foo=Hello"] }
        it { is_expected.to eq({"foo" => "Hello"}) }
      end

      context "with no value" do
        let(:argv) { ["--foo"] }

        it "raises MissingArgument" do
          expect { read }.to raise_error(OptionParser::MissingArgument, /--foo/)
        end
      end
    end

    context "when an integer is supplied" do
      context "via short argument" do
        let(:argv) { ["-z", "56"] }
        it { is_expected.to eq({"baz" => [56]}) }
      end

      context "via long argument" do
        let(:argv) { ["--baz", "56"] }
        it { is_expected.to eq({"baz" => [56]}) }
      end

      context "with a non-integer value" do
        let(:argv) { ["--baz", "1.7"] }

        it "raises InvalidArgument" do
          expect { read }.to raise_error(OptionParser::InvalidArgument, /--baz 1.7/)
        end
      end

      context "with no value" do
        let(:argv) { ["--baz"] }

        it "raises MissingArgument" do
          expect { read }.to raise_error(OptionParser::MissingArgument, /--baz/)
        end
      end
    end

    context "when a float is supplied" do
      context "via short argument" do
        let(:argv) { ["-m1.9"] }
        it { is_expected.to include("bam" => be_within(0.001).of(1.9)) }
      end

      context "via long argument" do
        let(:argv) { ["--bam=1.9"] }
        it { is_expected.to include("bam" => be_within(0.001).of(1.9)) }
      end

      context "with a non-numeric value" do
        let(:argv) { ["--bam=hi"] }

        it "raises InvalidArgument" do
          expect { read }.to raise_error(OptionParser::InvalidArgument, /--bam=hi/)
        end
      end

      context "with an integer value" do
        let(:argv) { ["--bam", "55"] }
        it { is_expected.to eq({"bam" => 55}) }
      end
    end
  end
end
