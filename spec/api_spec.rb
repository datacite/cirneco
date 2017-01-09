require 'spec_helper'

describe Cirneco::Work, vcr: true, :order => :defined do
  let(:doi) { "10.5072/0000-03VC" }
  let(:url) { "http://www.datacite.org" }
  let(:creators) { [{ given_name: "Elizabeth", family_name: "Miller", orcid: "0000-0001-5000-0007", affiliation: "DataCite" }] }
  let(:title) { "Full DataCite XML Example" }
  let(:publisher) { "DataCite" }
  let(:publication_year) { 2014 }
  let(:resource_type) { { value: "XML", resource_type_general: "Software" } }
  let(:metadata) { { "doi" => doi,
                     "url" => url,
                     "creators" => creators,
                     "title" => title,
                     "publisher" => publisher,
                     "publication_year" => publication_year,
                     "resource_type" => resource_type } }
  let(:media) { [{ mime_type: "application/pdf", url:"http://www.datacite.org/cirneco-test.pdf" }]}
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:options) { { username: username, password: password, sandbox: true } }
  let(:fixture_path) { "spec/fixtures/" }
  let(:samples_path) { "resources/kernel-4.0/samples/" }

  subject { Cirneco::Work.new(metadata,
                              media: media,
                              username: username,
                              password: password) }

  describe "Metadata API" do
    context "post" do
      it 'should post metadata' do
        response = subject.post_metadata(subject.data, options)
        expect(response.body["data"]).to eq("OK (10.5072/0000-03VC)")
        expect(response.status).to eq(201)
        expect(response.headers["Location"]).to eq("http://mds-sandbox.datacite.org/metadata/10.5072/0000-03VC")
      end
    end

    context "get" do
      it 'should get metadata' do
        response = subject.get_metadata(doi, options)
        expect(response.body["data"]).to eq(subject.data)
      end
    end

    context "delete" do
      it 'should delete metadata' do
        response = subject.delete_metadata(doi, options)
        expect(response.body["data"]).to eq("OK")
        expect(response.status).to eq(200)
      end
    end
  end

  describe "DOI API" do
    describe "put" do
      it 'should put doi' do
        response = subject.put_doi(doi, options.merge(url: url))
        expect(response.body["data"]).to eq("OK")
        expect(response.status).to eq(201)
      end
    end

    describe "get" do
      it 'should get all dois' do
        response = subject.get_dois(options)
        dois = response.body["data"]
        expect(dois.length).to eq(516)
        expect(dois.first).to eq("10.23725/0000-03VC")
      end

      it 'should get doi' do
        response = subject.get_doi(doi, options)
        expect(response.body["data"]).to eq("http://www.datacite.org")
      end

      it 'should get doi not found' do
        response = subject.get_doi("10.5072/0000-03V", options)
        expect(response.status).to eq(404)
      end

      it 'username missing' do
        options = { username: username, sandbox: true }
        response = subject.get_doi(doi, options)
        expect(response.body).to eq("errors"=>[{"title"=>"Username or password missing"}])
      end
    end
  end

  describe "Media API" do
    describe "post" do
      it 'should post media' do
        response = subject.post_media(doi, options.merge(media: media))
        expect(response.body["data"]).to eq("OK")
        expect(response.status).to eq(200)
      end
    end

    describe "get" do
      it 'should get media' do
        response = subject.get_media(doi, options)
        media = response.body["data"]
        expect(media.length).to eq(1)
        expect(media.first).to eq(:mime_type=>"application/pdf", :url=>"http://www.datacite.org/cirneco-test.pdf")
      end
    end
  end
end
