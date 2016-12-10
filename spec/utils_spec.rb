require 'spec_helper'

describe MdsClientRuby::Work, vcr: true, :order => :defined do
  let(:doi) { "10.23725/0000-03VC" }
  let(:creators) { [{ given_name: "Elizabeth", family_name: "Miller", orcid: "0000-0001-5000-0007", affiliation: "DataCite" }] }
  let(:title) { "Full DataCite XML Example" }
  let(:publisher) { "DataCite" }
  let(:publication_year) { 2014 }
  let(:resource_type) { { value: "XML", resource_type_general: "Software" } }
  let(:url) { "http://www.datacite.org" }
  let(:media) { [{ mime_type: "application/pdf", url:"http://www.datacite.org/mds-client-ruby-test.pdf" }]}
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:fixture_path) { "spec/fixtures/" }
  let(:samples_path) { "resources/kernel-4.0/samples/" }

  subject { MdsClientRuby::Work.new(doi: doi,
                                    creators: creators,
                                    title: title,
                                    publisher: publisher,
                                    publication_year: publication_year,
                                    resource_type: resource_type,
                                    url: url,
                                    media: media,
                                    username: username,
                                    password: password) }

  describe "get" do
    it 'should get all dois by prefix' do
      response = subject.get_dois_by_prefix(sandbox: true)
      dois = response.body["data"]
      expect(dois.length).to eq(4)
      expect(dois.first).to eq("10.23725/0000-03VC")
    end

    it 'should get highest doi by prefix' do
      response = subject.get_number_of_latest_doi(sandbox: true)
      expect(response.body["data"]).to eq(123)
    end

    it 'should get next doi' do
      response = subject.get_next_doi(sandbox: true)
      expect(response).to eq("10.23725/0000-03WD")
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
      expect(subject.encode_doi(number)).to eq("10.23725/0000-03VC")
    end
  end
end
