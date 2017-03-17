module JwsOnlineTestHelper
  def setup
    if live_jws_tests?
      WebMock.allow_net_connect!
    else
      setup_jws_mocking
    end
  end

  def teardown
    WebMock.disable_net_connect! if live_jws_tests?
  end

  def live_jws_tests?
    # not if running travis
    # ENV["TRAVIS"].nil?
    false
  end

  def setup_jws_mocking
    stub_request(:head, "#{Seek::Config.jws_online_root}/models/upload/").to_return(status: 200, body: '', headers: { 'Set-Cookie' => ['csrftoken=wejfvn322mnslWA'] })

    stub_request(:post, "#{Seek::Config.jws_online_root}/models/upload/").to_return(status: 302, body: '', headers: { location: 'http://jwsonline.net/models/fish-2/' })

    stub_request(:head, "https://#{URI.parse(Seek::Config.jws_online_root).host}/models/upload/").to_return(status: 200, body: '', headers: { 'Set-Cookie' => ['csrftoken=wejfvn322mnslWA'] })

    stub_request(:post, "https://#{URI.parse(Seek::Config.jws_online_root).host}/models/upload/").to_return(status: 302, body: '', headers: { location: 'http://jwsonline.net/models/fish-2/' })
  end
end
