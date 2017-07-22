require 'spec_helper'
require 'cirneco/cli'

describe Cirneco::Doi do
  let(:subject) do
    described_class.new
  end

  let(:number) { 123 }
  let(:prefix) { ENV['PREFIX'] }
  let(:doi) { "10.5438/0000-03VC" }
  let(:url) { "http://www.datacite.org" }
  let(:filename) { 'cool-dois/index.html' }
  let(:filepath) { fixture_path + filename }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:csl) { "spec/fixtures/apa.csl" }
  let(:bibliography) { "spec/fixtures/references.yaml" }
  let(:api_options) { { username: username, password: password, sandbox: true } }
  let(:mint_options) { { username: username, password: password, sandbox: true, source_dir: "/spec/fixtures/", build_dir: "/spec/fixtures/", csl: csl, bibliography: bibliography } }

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
        expect { subject.get "all" }.to output("10.23725/0000-03VC\n10.23725/0000-0A53\n10.23725/GQZDGNZW\n").to_stdout
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

    it 'updates accession_number for file' do
      expect { subject.name fixture_path + 'cool-dois.html.md' }.to output("Accession number MS-123 not changed for cool-dois.html.md\n").to_stdout
    end

    it 'updates accession_number for all files with opt-in' do
      subject.options = { opt_in: true }
      expect { subject.name fixture_path }.to output("Accession number MS-124 not changed for cool-dois-minted.html.md\nFile cool-dois-no-accession-number.html.md ignored: no empty accession_number\nAccession number MS-123 not changed for cool-dois.html.md\n").to_stdout
    end
  end

  context "base32" do
    it 'generates a doi' do
      subject.options = { number: number, prefix: prefix }
      expect { subject.generate }.to output("10.5438/0000-03VC\n").to_stdout
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

  context "mint and hide DOIs", vcr: true, :order => :defined do
    it 'mints a doi' do
      subject.options = mint_options
      expect { subject.mint filepath }.to output("DOI 10.5438/0000-03VC minted for cool-dois.html.md\n").to_stdout
    end

    it 'hides a doi' do
      filename = 'cool-dois-minted/index.html'
      filepath = fixture_path + filename
      subject.options = mint_options.merge(filepath: filepath)
      expect { subject.hide filepath }.to output("DOI 10.5438/55E5-T5C0 hidden for cool-dois-minted.html.md\n").to_stdout
    end

    it 'mints and hides a doi' do
      subject.options = mint_options
      expect { subject.mint_and_hide filepath }.to output("DOI 10.5438/0000-03VC minted and hidden for cool-dois.html.md\n").to_stdout
    end

    it 'mints dois for list of urls' do
      filepath = fixture_path + 'index.html'
      subject.options = mint_options
      expect { subject.mint filepath }.to output("DOI 10.5438/0000-03VC minted for cool-dois.html.md\nDOI 10.5438/0000-00SS minted for index.html.erb\n").to_stdout
    end

    it 'hides dois for list of urls' do
      filepath = fixture_path + 'index.html'
      subject.options = mint_options
      expect { subject.hide filepath }.to output("No DOI for cool-dois.html.md\nDOI 10.5438/0000-00SS hidden for index.html.erb\n").to_stdout
    end

    it 'mints and hides dois for list of urls' do
      filepath = fixture_path + 'index.html'
      subject.options = mint_options
      expect { subject.mint_and_hide filepath }.to output("DOI 10.5438/0000-03VC minted and hidden for cool-dois.html.md\nDOI 10.5438/0000-00SS minted and hidden for index.html.erb\n").to_stdout
    end
  end

  context "jats", vcr: true do
    it 'writes jats for list of urls' do
      filepath = fixture_path + 'index.html'
      subject.options = mint_options
      expect { subject.write_jats filepath }.to output("JATS XML written for cool-dois.html.md\nJATS XML written for index.html.erb\n").to_stdout
    end
  end
end
