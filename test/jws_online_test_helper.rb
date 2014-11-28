module JwsOnlineTestHelper

  def setup
    if live_jws_tests?
      WebMock.allow_net_connect!
    else
      setup_jws_mocking
    end
  end

  def teardown
    if live_jws_tests?
      WebMock.disable_net_connect!
    end
  end

  def live_jws_tests?
    #not if running travis
    ENV["TRAVIS"].nil?
  end

  def setup_jws_mocking
    stub_request(:head, "http://jws2.sysmo-db.org/models/upload/").to_return(:status => 200, :body => "", :headers => {"Set-Cookie"=>["csrftoken=wejfvn322mnslWA"]})

    stub_request(:post, "http://jws2.sysmo-db.org/models/upload/").to_return(:status => 302, :body => "", :headers => {:location=>"http://jwsonline.net/models/fish-2/"})

    stub_request(:head, "https://jws2.sysmo-db.org/models/upload/").to_return(:status => 200, :body => "", :headers => {"Set-Cookie"=>["csrftoken=wejfvn322mnslWA"]})

    stub_request(:post, "https://jws2.sysmo-db.org/models/upload/").to_return(:status => 302, :body => "", :headers => {:location=>"http://jwsonline.net/models/fish-2/"})
  end

end