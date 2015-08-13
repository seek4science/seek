module MockHelper

  ZENODO_ACCESS_TOKEN = '123'
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
  end

  def zenodo_oauth_mock
    stub_request(:post,
                 "https://sandbox.zenodo.org/oauth/token"
    ).to_return(
        :body => {:access_token => ZENODO_ACCESS_TOKEN.to_s}.to_json,
        :status => 200
    )
  end

end
