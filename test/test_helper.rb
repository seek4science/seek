ENV['RAILS_ENV'] ||= 'test'

require "coveralls"
Coveralls.wear!("rails")

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails/test_help'

require "minitest/reporters"
MiniTest::Reporters.use! MiniTest::Reporters::DefaultReporter.new

require 'rest_test_cases'
require 'rdf_test_cases'
require 'functional_authorization_tests'
require 'ruby-prof'
require 'factory_girl'
require 'webmock/test_unit'
require 'action_view/test_case'
require 'tmpdir'
require 'authenticated_test_helper'


module ActionView
  class Renderer
    def self.get_alternative key
      key = stringify_values(key)
      @@alternative_map[key]
    end
  end
end


FactoryGirl.find_definitions #It looks like requiring factory_girl _should_ do this automatically, but it doesn't seem to work

FactoryGirl.class_eval do
  def self.create_with_privileged_mode *args
    disable_authorization_checks {create_without_privileged_mode *args}
  end

  def self.build_with_privileged_mode *args
    disable_authorization_checks {build_without_privileged_mode *args}
  end

  class_alias_method_chain :create, :privileged_mode
  class_alias_method_chain :build, :privileged_mode
end

Kernel.class_eval do
  def as_virtualliver
    vl = Seek::Config.is_virtualliver
    Seek::Config.is_virtualliver=true
    yield
    Seek::Config.is_virtualliver=vl
  end

  def as_not_virtualliver
    vl = Seek::Config.is_virtualliver
    Seek::Config.is_virtualliver=false
    yield
    Seek::Config.is_virtualliver=vl
  end

  def with_auth_lookup_enabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=true
    yield
    Seek::Config.auth_lookup_enabled=val
  end

  def with_auth_lookup_disabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=false
    yield
    Seek::Config.auth_lookup_enabled=val
  end

  def with_alternative_rendering key,value
    current = ActionView::Renderer.get_alternative(key)
    ActionView::Renderer.define_alternative key,value
    yield
    if current.nil?
      ActionView::Renderer.clear_alternative key
    else
      ActionView::Renderer.define_alternative key,current
    end

  end

  def with_config_value config,value
    oldval = Seek::Config.send(config)
    Seek::Config.send("#{config.to_s}=",value)
    yield
    Seek::Config.send("#{config.to_s}=",oldval)
  end
end

class ActiveSupport::TestCase
  setup :clear_rails_cache
  teardown :clear_current_user


  def file_for_upload options={}
    default={:filename=>'little_file_v2.txt',:content_type=>'text/plain',:tempfile_fixture=>'files/little_file_v2.txt'}
    options = default.merge(options)
    ActionDispatch::Http::UploadedFile.new({
                                               :filename => options[:filename],
                                               :content_type => options[:content_type],
                                               :tempfile => fixture_file_upload(options[:tempfile_fixture])
                                           })
  end



  def check_for_soffice
    port = ConvertOffice::ConvertOfficeConfig.options[:soffice_port]
    @@soffice_available ||= begin
      soc = TCPSocket.new("localhost", port)
      soc.close
      true
    rescue
      false
    end
    skip("soffice is not available on port #{port}, skipping test") unless @@soffice_available
  end

  def skip_rest_schema_check?
    false
  end

  def clear_rails_cache
    Rails.cache.clear
  end

  def clear_current_user
    User.current_user = nil
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
  self.use_transactional_fixtures = true

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
  #fixtures :all

  set_fixture_class :sop_versions=>Sop::Version
  set_fixture_class :model_versions=>Model::Version
  set_fixture_class :data_file_versions=>DataFile::Version

  # Add more helper methods to be used by all tests here...

  #profiling

  def with_profiling
    start_profiling
    yield
    stop_profiling
  end

  def start_profiling
    RubyProf.start
  end

  def stop_profiling prefix="profile"
    results = RubyProf.stop
    html_path =  "#{Rails.root}/tmp/#{prefix}-graph.html"
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
  def mock_remote_file path,route,headers={},status=200
    headers = {'Content-Type' => 'image/png'}.merge headers
    stub_request(:get, route).to_return(:body => File.new(path), :status => status, :headers=>headers)
    stub_request(:head, route).to_return(:status=>status,:headers=>headers)
  end

  #mocks the contents of a http response with contents stored in a file
  # path - the http path to be mocked
  # mock_file - the name of the file that resides in test/fixtures/files/mocking and contains the contents of the response
  def mock_response_contents path,mock_file
    contents_path = File.join(Rails.root,"test","fixtures","files","mocking",mock_file)
    xml=File.open(contents_path,"r").read
    stub_request(:get,path).to_return(:status=>200,:body=>xml)
    path
  end

  def assert_emails n
    assert_difference "ActionMailer::Base.deliveries.size", n do
      yield
    end
  end

  def assert_no_emails
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      yield
    end
  end
  #debugging

  #saves the @response.body to a temp file, and prints out the file path
  def record_body
      dir=Dir.mktmpdir("seek")
      f=File.new("#{dir}/body.html","w+")
      f.write(@response.body)
      f.flush
      f.close
      puts "Written @response.body to #{f.path}"
  end
  
end

# Load seed data
#load "#{Rails.root}/db/seeds.rb" if File.exists?("#{Rails.root}/db/seeds.rb")
