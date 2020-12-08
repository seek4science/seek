require 'simplecov'
SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
require 'rails/test_help'

require 'rest_test_cases'
require 'rdf_test_cases'
require 'sharing_form_test_helper'
require 'general_authorization_test_cases'
require 'ruby-prof'
require 'factory_girl'
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

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]

Minitest::Test.i_suck_and_my_tests_are_order_dependent!

module ActionView
  class Renderer
    def self.get_alternative(key)
      key = stringify_values(key)
      @@alternative_map[key]
    end
  end
end

FactoryGirl.find_definitions # It looks like requiring factory_girl _should_ do this automatically, but it doesn't seem to work

Kernel.class_eval do
  def as_virtualliver
    vl = Seek::Config.is_virtualliver
    Seek::Config.is_virtualliver = true
    yield
    Seek::Config.is_virtualliver = vl
  end

  def as_not_virtualliver
    vl = Seek::Config.is_virtualliver
    Seek::Config.is_virtualliver = false
    yield
    Seek::Config.is_virtualliver = vl
  end

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
    Seek::Config.send("#{config}=", oldval)
  end
end

class ActiveSupport::TestCase
  setup :clear_rails_cache, :create_initial_person
  teardown :clear_current_user

  def file_for_upload
    fixture_file_upload('files/little_file_v2.txt', 'text/plain')
  end

  def check_for_soffice
    unless Seek::Config.soffice_available?(true)
      skip("soffice is not available on port #{ConvertOffice::ConvertOfficeConfig.options[:soffice_port]}, skipping test")
    end
  end

  def skip_rest_schema_check?
    false
  end

  # always create initial person, as this will always be an admin. Avoid some confusion in the tests where a person
  # is unexpectedly an admin
  def create_initial_person
    Factory(:admin, first_name: 'default admin')
  end

  # At least one sample attribute type is needed for building sample types from spreadsheets
  def create_sample_attribute_type
    Factory(:string_sample_attribute_type)
  end

  def clear_rails_cache
    Rails.cache.clear
    Seek::Config.clear_temporary_filestore
  end

  def clear_current_user
    User.current_user = nil
  end

  def add_avatar_to_test_object(obj)
    disable_authorization_checks do
      obj.avatar = Factory(:avatar, owner: obj)
      obj.save!
    end
  end

  def add_tags_to_test_object(obj)
    name = obj.class.to_s
    #for i in 1..5 do
    [1,2,3,4,5].each do |i|
      tag = Factory :tag, value: "#{name}-tag#{i}", source: User.current_user, annotatable: obj
      obj.reload
    end
  end

  def add_creator_to_test_object(obj)
    disable_authorization_checks do
      obj.creators = [Factory(:person)]
      obj.save!
    end
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

  def assert_no_emails
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      yield
    end
  end

  def assert_enqueued_emails(n)
    assert_difference(-> { ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j| j.fetch(:job) == ActionMailer::DeliveryJob }.count }, n) do
      yield
    end
  end

  def assert_no_enqueued_emails
    assert_no_difference(-> { ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j| j.fetch(:job) == ActionMailer::DeliveryJob }.count }) do
      yield
    end
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
# load "#{Rails.root}/db/seeds.rb" if File.exists?("#{Rails.root}/db/seeds.rb")

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
