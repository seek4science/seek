require File.dirname(__FILE__) + '/../test_helper'

class ExpertiseControllerTest < ActionController::TestCase
  
    fixtures :people, :expertises, :users
    
    include AuthenticatedTestHelper
    def setup
        login_as(:quentin)
    end
    
    def test_yourself_in_list
        
        expertise = expertises(:fishing)
        expertise.people << people(:one)
        expertise.people << people(:two)
        
        get :show, :id=>expertise
        
        assert_response :success
        assert_select %w(a.current_user), :text=>"Quentin Jones"
        assert_select %w(a), :text=>"Aaron Last_name"
        
    end
end
