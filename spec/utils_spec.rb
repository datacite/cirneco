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

  describe "get" do
    it 'should get all dois by prefix' do
      response = subject.get_dois_by_prefix(prefix, options)
      dois = response.body["data"]
      expect(dois.length).to eq(438)
      expect(dois.first).to eq("10.5438/0000-00SS")
    end
  end

  context "base32" do
    it 'should decode doi' do
      doi = "10.5438/0000-03WD"
      expect(subject.decode_doi(doi)).to eq(124)
    end

    it 'should decode doi not encoded' do
      doi = "10.23725/MDS-CLIENT-RUBY-TEST"
      expect(subject.decode_doi(doi)).to eq(0)
    end

    it 'should encode doi' do
      number = 123
      expect(subject.encode_doi(prefix, number: number)).to eq("10.5438/0000-03vc")
    end

    it 'should encode doi number with other characters' do
      number = "MS-123"
      expect(subject.encode_doi(prefix, number: number)).to eq("10.5438/0000-03vc")
    end

    it 'should encode doi random number' do
      expect(subject.encode_doi(prefix)).to start_with("10.5438")
    end

    it 'should encode doi with shoulder' do
      number = 7654321
      shoulder = "dryad."
      expect(subject.encode_doi(prefix, number: number, shoulder: shoulder)).to eq("10.5438/dryad.79jxhm")
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
  end
end
