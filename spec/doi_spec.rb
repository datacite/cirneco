require 'spec_helper'
require 'cirneco/cli'

describe Cirneco::Doi do
  let(:subject) do
    described_class.new
  end

  let(:number) { 123 }
  let(:prefix) { ENV['PREFIX'] }
  let(:doi) { "10.5072/0000-03VC" }
  let(:url) { "http://www.datacite.org" }
  let(:filename) { 'cool-dois.html.md' }
  let(:filepath) { fixture_path + filename }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:csl) { "spec/fixtures/apa.csl" }
  let(:bibliography) { "spec/fixtures/bibliography.yaml" }
  let(:api_options) { { username: username, password: password, sandbox: true } }

  describe "MDS DOI API", vcr: true, :order => :defined do
    context "put" do
      it 'should put doi' do
        subject.options = api_options.merge(url: url)
        expect { subject.put doi }.to output("OK\n").to_stdout
      end
    end

    context "get" do
      it 'should get all dois' do
        subject.options = api_options
        expect { subject.get "all" }.to output("10.23725/0000-03VC\n10.23725/0000-0A53\n10.23725/GQZDGNZW\n10.23725/MDS-CLIENT-RUBY-TEST\n10.5072/0000-03VC\n10.5438/0001\n10.5438/0002\n10.5438/0003\n10.5438/0004\n10.5438/0005\n10.5438/0006\n10.5438/EXAMPLE-FULL\n10.5438/MDS-CLIENT-RUBY-TEST\n").to_stdout
      end

      it 'should get doi' do
        subject.options = api_options
        expect { subject.get doi }.to output("http://www.datacite.org\n").to_stdout
      end

      it 'username missing' do
        subject.options = { username: username, sandbox: true }
        expect { subject.get doi }.to output("Error: Username or password missing\n").to_stdout
      end
    end
  end

  context "base32" do
    it 'generates a doi' do
      subject.options = { number: number, prefix: prefix }
      expect { subject.generate }.to output("10.5072/0000-03VC\n").to_stdout
    end

    it 'requires a prefix' do
      subject.options = { number: number }
      expect { subject.generate }.to output("No PREFIX provided. Use --prefix option or PREFIX ENV variable\n").to_stdout
    end

    it 'decodes a doi' do
      expect { subject.decode doi }.to output("DOI #{doi} was encoded with 123\n").to_stdout
    end

    it 'checks a doi' do
      expect { subject.check doi }.to output("Checksum for #{doi} is valid\n").to_stdout
    end

    it 'checks a doi invalid checksum' do
      doi = "5072/0000-03VA"
      expect { subject.check doi }.to output("Checksum for #{doi} is not valid\n").to_stdout
    end
  end

  context "mint and hide DOIs", :order => :defined do
    it 'mints a doi' do
      subject.options = { csl: csl, bibliography: bibliography }
      expect { subject.mint filepath }.to output("DOI 10.5072/0000-03VC minted for #{filename}\n").to_stdout
    end

    it 'hides a doi' do
      subject.options = { csl: csl, bibliography: bibliography }
      expect { subject.hide filepath }.to output("DOI 10.5072/0000-03VC hidden for #{filename}\n").to_stdout
    end

    it 'mints dois for contents of a folder' do
      subject.options = { csl: csl, bibliography: bibliography }
      expect { subject.mint fixture_path }.to output("DOI 10.5072/0000-03VC minted for #{filename}\n").to_stdout
    end

    it 'hides dois for contents of a folder' do
      subject.options = { csl: csl, bibliography: bibliography }
      expect { subject.hide fixture_path }.to output("DOI 10.5072/0000-03VC hidden for #{filename}\n").to_stdout
    end

    it 'should ignore non-markdown file for mint file' do
      filename = 'cool-dois.yml'
      expect { subject.mint fixture_path + filename }.to output("File #{filename} ignored: not a markdown file\n").to_stdout
    end

    it 'should ignore non-markdown file for hide file' do
      filename = 'cool-dois.yml'
      expect { subject.hide fixture_path + filename }.to output("File #{filename} ignored: not a markdown file\n").to_stdout
    end
  end
end


