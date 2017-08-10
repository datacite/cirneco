require 'spec_helper'

describe Cirneco::DataCenter, vcr: true, :order => :defined do
  let(:prefix) { ENV['PREFIX'] }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:source_dir) { "/spec/fixtures/" }
  let(:bibliography) { "spec/fixtures/references.yaml" }
  let(:options) { { username: username,
                    password: password,
                    sandbox: true,
                    build_dir: source_dir,
                    source_dir: source_dir } }

  subject { Cirneco::DataCenter.new(prefix: prefix,
                                    username: username,
                                    password: password) }

  context "accession_number" do
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
      expect(response).to eq("DOI 10.5438/55e5-t5c0 minted for cool-dois.html.md")
    end

    it 'should hide for url' do
      filepath = fixture_path + 'cool-dois-minted/index.html'
      response = subject.hide_doi_for_url(filepath, options)
      expect(response).to eq("DOI 10.5438/55e5-t5c0 hidden for cool-dois-minted.html.md")
    end

    it 'should mint and hide for url' do
      filepath = fixture_path + 'cool-dois/index.html'
      response = subject.mint_and_hide_doi_for_url(filepath, options)
      expect(response).to eq("DOI 10.5438/55e5-t5c0 minted and hidden for cool-dois.html.md")
    end

    it 'should mint for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.mint_dois_for_all_urls(filepath, options)
      expect(response).to eq("DOI 10.5438/55e5-t5c0 minted for cool-dois.html.md\nDOI 10.5438/0007-nw90 minted for index.html.erb")
    end

    it 'should hide for all urls' do
      filepath = fixture_path + 'index-minted.html'
      response = subject.hide_dois_for_all_urls(filepath, options)
      expect(response).to eq("No DOI for cool-dois.html.md\nErrors for DOI 10.5438/0000-nw90: Not found\n")
    end

    it 'should mint and hide for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.mint_and_hide_dois_for_all_urls(filepath, options)
      expect(response).to eq("DOI 10.5438/55e5-t5c0 minted and hidden for cool-dois.html.md\nDOI 10.5438/0000-00ss minted and hidden for index.html.erb")
    end

    it 'should get_json_ld_from_work' do
      filepath = fixture_path + 'cool-dois/index.html'
      json = subject.get_json_ld_from_work(filepath)
      metadata = JSON.parse(json)
      expect(metadata["url"]).to eq("https://blog.datacite.org/cool-dois/")
      expect(metadata["author"]).to eq([{"@type"=>"Person", "@id"=>"http://orcid.org/0000-0003-1419-2405", "givenName"=>"Martin", "familyName"=>"Fenner", "name"=>"Martin Fenner"}])
      expect(metadata["description"]).to eq("In 1998 Tim Berners-Lee coined the term cool URIs (1998), that is URIs that don’t change. We know that URLs referenced in the scholarly literature are often not cool, leading to link rot (Klein et al., 2014) and making it hard or impossible to find...")
      expect(metadata["citation"]).to eq([{"@type"=>"CreativeWork",
                                           "@id"=>"https://www.w3.org/Provider/Style/URI"},
                                          {"@type"=>"CreativeWork",
                                           "@id"=>"https://doi.org/10.1371/journal.pone.0115253"}])
      expect(metadata["isPartOf"]).to eq("@type"=>"Blog", "@id"=>"https://blog.datacite.org", "name"=>"DataCite Blog")
    end

    it 'should post_metadata_for_work' do
      filepath = fixture_path + 'cool-dois/index.html'
      json = subject.get_json_ld_from_work(filepath)
      response = subject.post_metadata_for_work(json, options)
      expect(response.body["data"]).to eq("OK")
      expect(response.status).to eq(201)
    end

    it 'should hide_metadata_for_work' do
      filepath = fixture_path + 'cool-dois/index.html'
      json = subject.get_json_ld_from_work(filepath)
      response = subject.hide_metadata_for_work(json, options)
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
      expect(subject.generate_jats_for_url(filepath, options.merge(bibliography: bibliography))).to eq("JATS XML written for cool-dois.html.md")
    end

    it 'should generate jats for all urls' do
      filepath = fixture_path + 'index.html'
      response = subject.generate_jats_for_all_urls(filepath, options)
      expect(response).to eq("JATS XML written for cool-dois.html.md\nJATS XML written for index.html.erb")
    end

    # it 'should validate jats xml' do
    #   filepath = fixture_path + 'cool-dois/index.html'
    #   expect(subject.generate_jats_for_url(filepath, options.merge(bibliography: bibliography))).to eq("JATS XML written for cool-dois.html.md")
    #   xml = IO.read(fixture_path + 'cool-dois/cool-dois.xml')
    #   expect(subject.validate_jats(xml).body["errors"]).to be_empty
    # end
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
