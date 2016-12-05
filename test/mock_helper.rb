module MockHelper

  ZENODO_ACCESS_TOKEN = '123'
  ZENODO_REFRESH_TOKEN = 'ref'
  ZENODO_DEPOSITION_ID = '456'
  ZENODO_FILE_ID = '789'

  def datacite_mock
    stub_request(:post, "https://test:test@test.datacite.org/mds/metadata").to_return(:body => 'OK (10.5072/my_test)', :status => 201)
    stub_request(:post, "https://test:test@test.datacite.org/mds/doi").to_return(:body => 'OK', :status => 201)
  end

  def zenodo_mock
    stub_request(:post,
                 "https://sandbox.zenodo.org/api/deposit/depositions?access_token=#{ZENODO_ACCESS_TOKEN}"
    ).to_return(
        :body => {:id => ZENODO_DEPOSITION_ID.to_s}.to_json,
        :status => 201
    )

    stub_request(:post,
                 "https://sandbox.zenodo.org/api/deposit/depositions/#{ZENODO_DEPOSITION_ID}/files?access_token=#{ZENODO_ACCESS_TOKEN}"
    ).to_return(
        :body => {:id => ZENODO_FILE_ID.to_s}.to_json,
        :status => 201
    )

    stub_request(:post,
                 "https://sandbox.zenodo.org/api/deposit/depositions/#{ZENODO_DEPOSITION_ID}/actions/publish?access_token=#{ZENODO_ACCESS_TOKEN}"
    ).to_return(
        :body => {:id => ZENODO_FILE_ID.to_s,
                  :submitted => true,
                  :record_url => "https://sandbox.zenodo.org/record/#{ZENODO_DEPOSITION_ID}"}.to_json,
        :status => 202
    )
  end

  def zenodo_oauth_mock
    stub_request(:post,
                 "https://sandbox.zenodo.org/oauth/token"
    ).with(:body => {:grant_type => 'authorization_code'}).to_return(
        :body => {
            :access_token => ZENODO_ACCESS_TOKEN.to_s,
            :refresh_token => ZENODO_REFRESH_TOKEN.to_s,
            :expires_in => 3600,
            :scope => "deposit:write deposit:actions",
            :token_type => "Bearer"
        }.to_json,
        :status => 200
    )

    stub_request(:post,
                 "https://sandbox.zenodo.org/oauth/token"
    ).with(:body => {:grant_type => 'refresh_token'}).to_return(
        :body => {
            :access_token => ZENODO_ACCESS_TOKEN.to_s,
            :refresh_token => ZENODO_REFRESH_TOKEN.to_s,
            :expires_in => 3600,
            :scope => "deposit:write deposit:actions",
            :token_type => "Bearer"
        }.to_json,
        :status => 200
    )
  end

  def doi_citation_mock
    stub_request(:get, /https:\/\/dx\.doi\.org\/.+/).
        with(headers: {'Accept' => 'application/vnd.citationstyles.csl+json'}).
        to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)

    stub_request(:get, "https://dx.doi.org/10.5072/test").
        with(headers: {'Accept' => 'application/vnd.citationstyles.csl+json'}).
        to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)

    stub_request(:get, "https://dx.doi.org/10.5072/broken").
        with(headers: {'Accept' => 'application/vnd.citationstyles.csl+json'}).
        to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/broken_doi_metadata_response.html"), status: 200)
  end

  def publication_formatter_mock
    stub_request(:post, "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi").
        with(body: { 'db'=>'pubmed', 'email'=>'()', 'id'=>'5', 'retmode'=>'text', 'rettype'=>'medline', 'tool'=>'bioruby' },
             headers: { 'Accept'=>'*/*',
                        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Content-Length'=>'69',
                        'Content-Type'=>'application/x-www-form-urlencoded',
                        'User-Agent'=>'Ruby' }).
        to_return(status: 200, body: File.new("#{Rails.root}/test/fixtures/files/mocking/efetch_response.txt"))
  end

end
