require 'spec_helper'

describe MdsClientRuby::DataCenter, vcr: true, :order => :defined do
  let(:prefix) { ENV['PREFIX'] }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:options) { { username: username, password: password, sandbox: true } }

  subject { MdsClientRuby::DataCenter.new(prefix: prefix,
                                          username: username,
                                          password: password) }

  describe "get" do
    it 'should get all dois by prefix' do
      response = subject.get_dois_by_prefix(prefix, options)
      dois = response.body["data"]
      expect(dois.length).to eq(4)
      expect(dois.first).to eq("10.23725/0000-03VC")
    end

    it 'should get_number_of_latest_doi' do
      response = subject.get_number_of_latest_doi(prefix, options)
      expect(response.body["data"]).to eq(123)
    end

    it 'should get next doi' do
      response = subject.get_next_doi(prefix, options)
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
      expect(subject.encode_doi(prefix, number)).to eq("10.23725/0000-03VC")
    end
  end
end
