require 'simplecov'
SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'sharing_form_test_helper'
require 'general_authorization_test_cases'
require 'ruby-prof'
require 'factory_bot'
require 'webmock/minitest'
require 'action_view/test_case'
require 'tmpdir'
require 'authenticated_test_helper'
require 'mock_helper'
require 'html_helper'
require 'nels_test_helper'
require 'minitest/reporters'
require 'minitest'
require 'ostruct'
require 'pry'
require 'api_test_helper'
require 'integration/api/read_api_test_suite'
require 'integration/api/write_api_test_suite'
require 'rdf_test_cases'
require 'rack_test_cookie_jar_extensions'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(fast_fail: true,
                                                                   color: true,
                                                                   detailed_skip: false,
                                                                   slow_count: 10)] unless ENV['RM_INFO']

Minitest::Test.i_suck_and_my_tests_are_order_dependent!

module ActionView
  class Renderer
    def self.get_alternative(key)
      key = stringify_values(key)
      @@alternative_map[key]
    end
  end
end

FactoryBot.find_definitions # It looks like requiring factory_bot _should_ do this automatically, but it doesn't seem to work

Kernel.class_eval do

  def with_auth_lookup_enabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = true
    yield
    Seek::Config.auth_lookup_enabled = val
  end

  def with_auth_lookup_disabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = false
    yield
    Seek::Config.auth_lookup_enabled = val
  end

  def with_alternative_rendering(key, value)
    current = ActionView::Renderer.get_alternative(key)
    ActionView::Renderer.define_alternative key, value
    yield
    if current.nil?
      ActionView::Renderer.clear_alternative key
    else
      ActionView::Renderer.define_alternative key, current
    end
  end

  def with_config_value(config, value)
    oldval = Seek::Config.send(config)
    Seek::Config.send("#{config}=", value)
    yield
  ensure
    Seek::Config.send("#{config}=", oldval)
  end

  def with_config_values(settings)
    oldvals = {}
    settings.each do |config, value|
      oldvals[config] = Seek::Config.send(config)
      Seek::Config.send("#{config}=", value)
    end
    yield
  ensure
    oldvals.each do |config, oldval|
      Seek::Config.send("#{config}=", oldval)
    end
  end

  def with_relative_root(root)
    oldval = Rails.application.config.relative_url_root
    Rails.application.config.relative_url_root = root
    Rails.application.default_url_options = Seek::Config.site_url_options
    yield
    Rails.application.config.relative_url_root = oldval
    Rails.application.default_url_options = Seek::Config.site_url_options
  end
end

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup :clear_rails_cache, :create_initial_person
  teardown :clear_current_user

  def file_for_upload
    fixture_file_upload('little_file_v2.txt', 'text/plain')
  end

  def skip_rest_schema_check?
    false
  end

  # always create initial person, as this will always be an admin. Avoid some confusion in the tests where a person
  # is unexpectedly an admin
  def create_initial_person
    disable_authorization_checks { FactoryBot.create(:admin, first_name: 'default admin') }
  end

  # At least one sample attribute type is needed for building sample types from spreadsheets
  def create_sample_attribute_type
    FactoryBot.create(:string_sample_attribute_type)
  end

  def clear_rails_cache
    Rails.cache.clear
    Seek::Config.clear_temporary_filestore
  end

  def clear_current_user
    User.current_user = nil
  end

  def perform_jsonapi_checks
    assert_response :success
    assert_equal 'application/vnd.api+json', @response.media_type
    assert JSON::Validator.validate(File.join(Rails.root, 'public', 'api', 'jsonapi-schema-v1'),
                                    @response.body), 'Response did not validate against JSON-API schema'
  end

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_tests = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  set_fixture_class sop_versions: Sop::Version
  set_fixture_class model_versions: Model::Version
  set_fixture_class data_file_versions: DataFile::Version

  # Add more helper methods to be used by all tests here...

  # profiling

  def with_profiling
    start_profiling
    yield
    stop_profiling
  end

  def start_profiling
    RubyProf.start
  end

  def stop_profiling(prefix = 'profile')
    results = RubyProf.stop
    html_path = "#{Rails.root}/tmp/#{prefix}-graph.html"
    txt_path = "#{Rails.root}/tmp/#{prefix}-flat.txt"
    File.open html_path, 'w' do |file|
      RubyProf::GraphHtmlPrinter.new(results).print(file)
    end
    puts "HTML profile written to: #{html_path}"
    File.open txt_path, 'w' do |file|
      RubyProf::FlatPrinter.new(results).print(file)
    end
    puts "Flat profile written to: #{txt_path}"
  end

  ## stuff for mocking
  def mock_remote_file(path, route, headers = {}, status = 200)
    headers = { 'Content-Type' => 'image/png' }.merge headers
    stub_request(:get, route).to_return(body: File.new(path), status: status, headers: headers)
    stub_request(:head, route).to_return(status: status, headers: headers)
  end

  # mocks the contents of a http response with contents stored in a file
  # path - the http path to be mocked
  # mock_file - the name of the file that resides in test/fixtures/files/mocking and contains the contents of the response
  def mock_response_contents(path, mock_file)
    contents_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'mocking', mock_file)
    xml = File.open(contents_path, 'r').read
    stub_request(:get, path).to_return(status: 200, body: xml)
    path
  end

  # debugging

  # saves the @response.body to a temp file, and prints out the file path
  def record_body
    dir = Dir.mktmpdir('seek')
    f = File.new("#{dir}/body.html", 'w+')
    f.write(@response.body)
    f.flush
    f.close
    puts "Written @response.body to #{f.path}"
  end

  def clear_flash(target = nil)
    if target.nil?
      @request.session.delete('flash')
    elsif request.session['flash'] && request.session['flash']['flashes']
      @request.session['flash']['flashes'].delete(target.to_s)
    end
  end

  def open_fixture_file(path)
    File.open(File.join(Rails.root, 'test', 'fixtures', 'files', *path.split('/')))
  end
end

# Load seed data
# load "#{Rails.root}/db/seeds.rb" if File.exist?("#{Rails.root}/db/seeds.rb")

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock

  # ignore sparql requests, for some of the RDF integration tests
  # fixme: in the future it would be good to make the sparql data consistent enough to work with VCR
  config.ignore_request do |request|
    request.uri =~ /sparql-auth/
  end
end

WebMock.disable_net_connect!(allow_localhost: true) # Need to comment this line out when running VCRs for the first time

# Clear testing filestore before test run (but check its under tmp for safety)
if File.expand_path(Seek::Config.filestore_path).start_with?(File.expand_path(File.join(Rails.root, 'tmp')))
  FileUtils.rm_r(Seek::Config.filestore_path)
end

class ActionController::TestCase
  def self._get_base_host
    # Cache host_with_port in a variable to avoid adding lots of overhead to each test
    @host_with_port ||= Seek::Config.host_with_port
  end

  # Ensure the Host in requests is the configured host from the settings instead of the default "test.host"
  setup do
    request.host = self.class._get_base_host
  end
end
