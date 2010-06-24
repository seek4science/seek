require 'test_helper'
require 'rest_test_cases'

class StrainsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
    @object=strains(:yeast1)
  end
end
