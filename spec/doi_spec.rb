require 'spec_helper'
require 'cirneco/cli'

describe Cirneco::Doi do
  let(:subject) do
    described_class.new
  end

  let(:number) { 123 }
  let(:prefix) { ENV['PREFIX'] }
  let(:doi) { "10.5072/nmr3-xm61" }
  let(:url) { "http://www.datacite.org" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
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
        subject.options = api_options.merge(limit: 3)
        expect { subject.get "all" }.to output("10.5438/0000-00SS\n10.5438/0000-01HC\n10.5438/0000-03VC\n").to_stdout
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

  context "accession_number" do
    it 'generates an accession_number' do
      subject.options = { number: number }
      expect { subject.accession_number }.to output("MS-123\n").to_stdout
    end
  end

  context "base32" do
    it 'generates a doi' do
      subject.options = { number: number, prefix: prefix }
      expect { subject.generate }.to output("10.5438/0000-3v20\n").to_stdout
    end

    it 'requires a prefix' do
      subject.options = { number: number }
      expect { subject.generate }.to output("No PREFIX provided. Use --prefix option or PREFIX ENV variable\n").to_stdout
    end

    it 'decodes a doi' do
      expect { subject.decode doi }.to output("DOI #{doi} was encoded with 726405044\n").to_stdout
    end

    it 'checks a doi' do
      expect { subject.check doi }.to output("Checksum for #{doi} is valid\n").to_stdout
    end

    it 'checks a doi invalid checksum' do
      doi = "5072/0000-03VA"
      expect { subject.check doi }.to output("Checksum for #{doi} is not valid\n").to_stdout
    end
    it 'checks a doi usercase' do
      doi = "5072/0000-0098"
      expect { subject.check doi }.to output("Checksum for #{doi} is valid\n").to_stdout
    end
  end
end
