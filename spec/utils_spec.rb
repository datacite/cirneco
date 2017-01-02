require 'spec_helper'

describe Cirneco::DataCenter, vcr: true, :order => :defined do
  let(:prefix) { ENV['PREFIX'] }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:source_dir) { "/spec/fixtures/" }
  let(:options) { { username: username,
                    password: password,
                    sandbox: true,
                    build_dir: source_dir,
                    source_dir: source_dir } }

  subject { Cirneco::DataCenter.new(prefix: prefix,
                                    username: username,
                                    password: password) }

  describe "get" do
    it 'should get all dois by prefix' do
      response = subject.get_dois_by_prefix(prefix, options)
      dois = response.body["data"]
      expect(dois.length).to eq(76)
      expect(dois.first).to eq("10.5072/0000-00SS")
    end
  end

  context "base32" do
    it 'should decode doi' do
      doi = "10.5072/0000-03WD"
      expect(subject.decode_doi(doi)).to eq(124)
    end

    it 'should decode doi not encoded' do
      doi = "10.23725/MDS-CLIENT-RUBY-TEST"
      expect(subject.decode_doi(doi)).to eq(0)
    end

    it 'should encode doi' do
      number = 123
      expect(subject.encode_doi(prefix, number: number)).to eq("10.5072/0000-03VC")
    end

    it 'should encode doi number with other characters' do
      number = "MS-123"
      expect(subject.encode_doi(prefix, number: number)).to eq("10.5072/0000-03VC")
    end

    it 'should encode doi random number' do
      expect(subject.encode_doi(prefix)).to start_with("10.5072")
    end
  end

  context "accession_number" do
    it 'should generate' do
      number = 123
      expect(subject.generate_accession_number(number: number)).to eq("MS-123")
    end

    it 'should generate with fixed length' do
      number = 123
      length = 8
      expect(subject.generate_accession_number(number: number, length: length)).to eq("MS-00000123")
    end

    it 'should generate with fixed length and hyphen' do
      number = 123
      length = 8
      split = 4
      expect(subject.generate_accession_number(number: number, length: length, split: split)).to eq("MS-0000-0123")
    end

    it 'should generate random' do
      random_number = subject.generate_accession_number.scan(/\d+/).first.to_i
      expect(random_number).to be_between(1, 1000000).inclusive
    end

    it 'should generate random lower_limit' do
      lower_limit = 1000000
      random_number = subject.generate_accession_number(lower_limit: lower_limit).scan(/\d+/).first.to_i
      expect(random_number).to be_between(1000001, 2000000).inclusive
    end

    it 'should generate with namespace' do
      number = 123
      namespace = 'DD'
      expect(subject.generate_accession_number(number: number, namespace: namespace)).to eq("DD123")
    end

    it 'should get existing' do
      filepath = fixture_path + 'cool-dois.html.md'
      response = subject.get_accession_number(filepath)
      expect(response).to eq(123)
    end

    it 'should get existing for folder' do
      response = subject.get_all_accession_numbers(fixture_path)
      expect(response).to eq([123, 124])
    end

    it 'should update for file' do
      filepath = fixture_path + 'cool-dois.html.md'
      response = subject.update_accession_number(filepath)
      expect(response).to eq("Accession number MS-123 not changed for cool-dois.html.md")
    end

    it 'should update for all files' do
      response = subject.update_all_accession_numbers(fixture_path, opt_in: true)
      expect(response).to eq(["Accession number MS-124 not changed for cool-dois-minted.html.md", "File cool-dois-no-accession-number.html.md ignored: no empty accession_number", "Accession number MS-123 not changed for cool-dois.html.md"])
    end
  end

  context "mint and hide DOIs" do
    it 'get urls for works' do
      filepath = fixture_path + 'index.html'
      response = subject.get_urls_for_works(filepath)
      expect(response.length).to eq(2)
    end

    it 'should mint for url' do
      filepath = fixture_path + 'cool-dois/index.html'
      response = subject.mint_doi_for_url(filepath, options)
      expect(response).to eq("DOI 10.5072/0000-03VC minted for cool-dois.html.md")
    end

    it 'should hide for url' do
      filepath = fixture_path + 'cool-dois-minted.html'
      response = subject.hide_doi_for_url(filepath, options)
      expect(response).to eq("DOI 10.5072/0000-03WD hidden for cool-dois-minted.html.md")
    end

    it 'should mint and hide for url' do
      filepath = fixture_path + 'cool-dois/index.html'
      response = subject.mint_and_hide_doi_for_url(filepath, options)
      expect(response).to eq("DOI 10.5072/0000-03VC minted and hidden for cool-dois.html.md")
    end

    it 'should mint for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.mint_dois_for_all_urls(filepath, options)
      expect(response).to eq("DOI 10.5072/0000-03VC minted for cool-dois.html.md\nDOI 10.5072/0000-00SS minted for index.html.erb")
    end

    it 'should hide for all urls' do
      filepath = fixture_path + 'index-minted.html'
      response = subject.hide_dois_for_all_urls(filepath, options)
      expect(response).to eq("No DOI for cool-dois.html.md\nErrors for DOI 10.5072/0000-NW90: Not found\n")
    end

    it 'should mint and hide for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.mint_and_hide_dois_for_all_urls(filepath, options)
      expect(response).to eq("DOI 10.5072/0000-03VC minted and hidden for cool-dois.html.md\nDOI 10.5072/0000-00SS minted and hidden for index.html.erb")
    end

    it 'should generate metadata for work' do
      filepath = fixture_path + 'cool-dois/index.html'
      metadata = subject.generate_metadata_for_work(filepath)
      expect(metadata["url"]).to eq("https://blog.datacite.org/cool-dois/")
      expect(metadata["creators"]).to eq([{:given_name=>"Martin", :family_name=>"Fenner", :orcid=>"0000-0003-1419-2405"}])
      expect(metadata["descriptions"]).to eq([{:value=>"In 1998 Tim Berners-Lee coined the term cool URIs (1998), that is URIs that don’t change. We know that URLs referenced in the scholarly literature are often not cool, leading to link rot (Klein et al., 2014) and making it hard or impossible to find...",:description_type=>"Abstract"}])
      expect(metadata["related_identifiers"]).to eq([{:value=>"https://www.w3.org/Provider/Style/URI",
          :related_identifier_type=>"URL",
          :relation_type=>"References"},
        { :value=>"10.1371/JOURNAL.PONE.0115253",
          :related_identifier_type=>"DOI",
          :relation_type=>"References" },
        { :value=>"https://blog.datacite.org/",
          :related_identifier_type=>"URL",
          :relation_type=>"IsPartOf"}])
    end

    it 'should generate metadata for work no JSON-LD' do
      filepath = fixture_path + 'cool-dois-no-json-ld/index.html'
      expect(subject.generate_metadata_for_work(filepath)).to eq("Error: no schema.org metadata found")
    end

    it 'should generate metadata for work missing required metadata' do
      filepath = fixture_path + 'cool-dois-missing-metadata/index.html'
      expect(subject.generate_metadata_for_work(filepath)).to eq("Error: required metadata missing")
    end

    it 'should post_metadata_for_work' do
      filepath = fixture_path + 'cool-dois/index.html'
      metadata = subject.generate_metadata_for_work(filepath)
      response = subject.post_metadata_for_work(metadata, options)
      expect(response.body["data"]).to eq("OK")
      expect(response.status).to eq(201)
    end

    it 'should hide_metadata_for_work' do
      filepath = fixture_path + 'cool-dois/index.html'
      metadata = subject.generate_metadata_for_work(filepath)
      response = subject.hide_metadata_for_work(metadata, options)
      expect(response.body["data"]).to eq("OK")
      expect(response.status).to eq(200)
    end
  end

  context "jats" do
    it 'should generate metadata for jats' do
      filepath = fixture_path + 'cool-dois/index.html'
      metadata = subject.generate_metadata_for_jats(filepath)
      expect(metadata["author"]).to eq([{"given_name"=>"Martin", "family_name"=>"Fenner", "orcid"=>"0000-0003-1419-2405"}])
      expect(metadata["license_url"]).to eq("https://creativecommons.org/licenses/by/4.0/")
    end

    it 'should generate jats xml' do
      filepath = fixture_path + 'cool-dois/index.html'
      expect(subject.generate_jats_for_url(filepath, options)).to eq("JATS XML written for cool-dois.html.md")
    end

    it 'should generate jats for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.generate_jats_for_all_urls(filepath, options)
      expect(response).to eq("JATS XML written for cool-dois.html.md\nJATS XML written for index.html.erb")
    end
  end

  context "get_related_identifiers" do
    it 'isPartOf' do
      metadata = { "isPartOf" => {
        "@type" => "Blog",
        "@id" => "https://blog.datacite.org",
        "name" => "DataCite Blog" } }
      expect(subject.get_related_identifiers(metadata)).to eq([{:value=>"https://blog.datacite.org/", :related_identifier_type=>"URL", :relation_type=>"IsPartOf"}])
    end
  end

  context "filepath from url" do
    it 'https://blog.datacite.org/' do
      url = 'https://blog.datacite.org/'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("index.html.erb")
      expect(source_path).to eq(fixture_path + "index.html.erb")
      expect(build_path).to eq(fixture_path + "index.html")
    end

    it 'https://blog.datacite.org' do
      url = 'https://blog.datacite.org'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("index.html.erb")
      expect(source_path).to eq(fixture_path + "index.html.erb")
      expect(build_path).to eq(fixture_path + "index.html")
    end

    it 'index.html' do
      url = fixture_path + 'index.html'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("index.html.erb")
      expect(source_path).to eq(fixture_path + "index.html.erb")
      expect(build_path).to eq(fixture_path + "index.html")
    end

    it 'index.html basename' do
      url = 'index.html'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("index.html.erb")
      expect(source_path).to eq(fixture_path + "index.html.erb")
      expect(build_path).to eq(fixture_path + "index.html")
    end

    it 'cool-dois.html' do
      url = fixture_path + 'cool-dois.html'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("cool-dois.html.md")
      expect(source_path).to eq(fixture_path + "cool-dois.html.md")
      expect(build_path).to eq(fixture_path + "cool-dois/index.html")
    end

    it 'cool-dois.html basename' do
      url = 'cool-dois.html'
      filename, build_path, source_path = subject.filepath_from_url(url, build_dir: source_dir, source_dir: source_dir)
      expect(filename).to eq("cool-dois.html.md")
      expect(source_path).to eq(fixture_path + "cool-dois.html.md")
      expect(build_path).to eq(fixture_path + "cool-dois/index.html")
    end
  end
end
