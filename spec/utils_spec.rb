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
  end
end
