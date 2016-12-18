require 'spec_helper'

describe Cirneco::DataCenter, vcr: true, :order => :defined do
  let(:prefix) { ENV['PREFIX'] }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:options) { { username: username, password: password, sandbox: true } }

  subject { Cirneco::DataCenter.new(prefix: prefix,
                                    username: username,
                                    password: password) }

  describe "get" do
    it 'should get all dois by prefix' do
      response = subject.get_dois_by_prefix(prefix, options)
      dois = response.body["data"]
      expect(dois.length).to eq(4)
      expect(dois.first).to eq("10.23725/0000-03VC")
    end
  end

  describe "base32" do
    it 'should decode doi' do
      doi = "10.23725/0000-03WD"
      expect(subject.decode_doi(doi)).to eq(124)
    end

    it 'should decode doi not encoded' do
      doi = "10.23725/MDS-CLIENT-RUBY-TEST"
      expect(subject.decode_doi(doi)).to eq(0)
    end

    it 'should encode doi' do
      number = 123
      expect(subject.encode_doi(prefix, number: number)).to eq("10.23725/0000-03VC")
    end

    it 'should encode doi random number' do
      expect(subject.encode_doi(prefix)).to start_with("10.23725")
    end
  end

  describe "register" do
    it 'should register_file' do
      filepath = fixture_path + 'cool-dois.html.md'
      number = 123
      response = subject.register_file(filepath, number: number)
      expect(response).to eq("DOI 10.23725/0000-03VC added to cool-dois.html.md")
    end

    it 'should register_file unregister' do
      filepath = fixture_path + 'cool-dois.html.md'
      response = subject.register_file(filepath, unregister: true)
      expect(response).to eq("DOI removed from cool-dois.html.md")
    end

    it 'should register_all_files unregister' do
      number = 123
      response = subject.register_all_files(fixture_path, number: number, unregister: true)
      expect(response).to eq("DOI removed from cool-dois.html.md")
    end

    it 'should ignore non-markdown file for register_file' do
      filepath = fixture_path + 'cool-dois.yml'
      response = subject.register_file(filepath)
      expect(response).to eq("File cool-dois.yml ignored: not a markdown file")
    end

    it 'should generate metadata for work' do
      filepath = fixture_path + 'cool-dois.html.md'
      number = 123
      metadata = subject.generate_metadata_for_work(filepath, number: number, csl: 'spec/fixtures/apa.csl', bibliography: 'spec/fixtures/references.bib')
      expect(metadata["url"]).to eq("https://blog.datacite.org/cool-dois/")
      expect(metadata["creators"]).to eq([{:given_name=>"Martin", :family_name=>"Fenner", :orcid=>"0000-0003-1419-2405"}])
      expect(metadata["descriptions"]).to eq([{:value=>"In 1998 Tim Berners-Lee coined the term cool URIs (1998), that is URIs that don’t change. We know that URLs referenced in the scholarly literature are often not cool, leading to link rot (Klein et al., 2014) and making it hard or impossible to find...",:description_type=>"Abstract"}])
      expect(metadata["related_identifiers"]).to eq([{:value=>"https://www.w3.org/Provider/Style/URI",
          :related_identifier_type=>"URL",
          :relation_type=>"References"},
        { :value=>"10.1371/JOURNAL.PONE.0115253",
          :related_identifier_type=>"DOI",
          :relation_type=>"References" }])
    end

    it 'should create_work_from_yaml' do
      filepath = fixture_path + 'cool-dois.html.md'
      number = 123
      metadata = subject.generate_metadata_for_work(filepath, number: number, csl: 'spec/fixtures/apa.csl', bibliography: 'spec/fixtures/references.bib')
      work = subject.create_work_from_metadata(metadata)
      puts work.inspect
      expect(work.validation_errors).to be_empty
    end
  end
end
