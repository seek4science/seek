ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'test_benchmark'
require 'rest_test_cases'
require 'ruby-prof'
require 'factory_girl'
Factory.find_definitions #It looks like requiring factory_girl _should_ do this automatically, but it doesn't seem to work

class ActiveSupport::TestCase
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
  set_fixture_class :taggings=>ActsAsTaggableOn::Tagging
  set_fixture_class :tags=>ActsAsTaggableOn::Tag

  # Add more helper methods to be used by all tests here...

  #profiling

  def start_profiling
    RubyProf.start
  end

  def stop_profiling prefix="profile"
    results = RubyProf.stop

    File.open "#{RAILS_ROOT}/tmp/#{prefix}-graph.html", 'w' do |file|
      RubyProf::GraphHtmlPrinter.new(results).print(file)
    end
  end
end
