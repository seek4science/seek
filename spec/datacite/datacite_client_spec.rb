require 'spec_helper'
require 'datacite/client'

describe DataCite::Client do
  let(:endpoint)    { DataCite::Client.new('test', 'test', DataCite::Client::TEST_ENDPOINT) }
  let(:doi)    { '10.5072/MY_TEST' }
  let(:url)    { 'https://seek.sysmo-db.org' }

  describe 'resolve a DOI',
           vcr: { cassette_name: 'resolve_a_DOI/returns_a_url_associated_with_a_given_DOI' } do
    it 'returns a url associated with a given DOI' do
      expect(endpoint.resolve(doi)).to eq(url)
    end

    it 'returns a 401 for un-authorized account',
       vcr: { cassette_name: 'resolve_a_DOI/returns_a_401_for_un-authorized_account' } do
      invalid_user = 'invalid'
      invalid_password = 'invalid'
      endpoint = DataCite::Client.new(invalid_user, invalid_password, DataCite::Client::TEST_ENDPOINT)
      expect { endpoint.resolve(doi) }.to raise_error(RestClient::Unauthorized)
    end

    it 'returns a 404 for not-found DOI',
       vcr: { cassette_name: 'resolve_a_DOI/returns_a_404_for_not-found_DOI' } do
      doi = 'non-existing'
      expect { endpoint.resolve(doi) }.to raise_error(RestClient::ResourceNotFound)
    end
  end

  describe 'mint a DOI' do
    context 'DOI does not exist' do
      it 'mints a new DOI', vcr: { cassette_name: 'mint_a_DOI/mints_a_new_DOI' } do
        metadata = open_test_metadata('my_test.xml')
        expect(endpoint.upload_metadata(metadata)).to eq('OK (10.5072/my_test)')
        expect(endpoint.mint(doi, url)).to eq('OK')
        expect(endpoint.resolve(doi)).to eq(url)
      end

      it 'returns 412 if metadata has not been uploaded',
         vcr: { cassette_name: 'mint_a_DOI/returns_412_if_metadata_has_not_been_uploaded' } do
        new_doi = '10.5072/new_doi'
        # 412 Precondition failed
        expect { endpoint.mint(new_doi, url) }.to raise_error(RestClient::PreconditionFailed)
      end
    end

    context 'DOI exists' do
      it 'updates the URL if different',
         vcr: { cassette_name: 'mint_a_DOI/updates_the_URL_if_different' } do
        # use test_doi.xml so that it does not update the url of my_test.xml
        metadata = open_test_metadata('test_doi.xml')
        doi = '10.5072/test_doi'
        expect(endpoint.upload_metadata(metadata)).to eq('OK (10.5072/test_doi)')
        expect(endpoint.mint(doi, url)).to eq('OK')
        expect(endpoint.resolve(doi)).to eq(url)

        new_url = 'https://seek.sysmo-db.org/data_files'
        expect(endpoint.mint(doi, new_url)).to eq('OK')
        expect(endpoint.resolve(doi)).to eq(new_url)
      end
    end
  end

  describe 'retrieve metadata' do
    it 'returns metadata associated with a given DOI',
       vcr: { cassette_name: 'retrieve_metadata/returns_metadata_associated_with_a_given_DOI' } do
      metadata = open_test_metadata('my_test.xml')
      expect(endpoint.metadata(doi)).to eq(metadata)
    end

    it 'returns 404 for not found DOI',
       vcr: { cassette_name: 'retrieve_metadata/returns_404_for_not_found_DOI' } do
      doi = 'non-existing'
      expect { endpoint.metadata(doi) }.to raise_error(RestClient::ResourceNotFound)
    end
  end

  describe 'upload metadata' do
    it 'creates new version of metadata',
       vcr: { cassette_name: 'upload_metadata/creates_new_version_of_metadata' } do
      metadata = open_test_metadata('my_test.xml')
      expect(endpoint.upload_metadata(metadata)).to eq('OK (10.5072/my_test)')
    end

    it 'returns 400 for an invalid xml',
       vcr: { cassette_name: 'upload_metadata/returns_400_for_an_invalid_xml' } do
      # metadata without a DOI => Bad request
      metadata = open_test_metadata('invalid_doi.xml')
      expect { endpoint.upload_metadata(metadata) }.to raise_error(RestClient::BadRequest)
    end
  end

  describe 'inactivate a DOI' do
    it 'marks a dataset as inactive'
  end

  describe 'activate a DOI' do
    context 'after a DOI being inactivated' do
      it 'post new metadata for a given DOI'
    end
  end

  private

  def open_test_metadata(filename)
    file = File.join 'spec/', '/metadata_files/', filename
    open(file).read
  end
  # TODO: Media API
end
