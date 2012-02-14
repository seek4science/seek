require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    assert_equal [DataFile,Model,Presentation,Publication,Sop,Assay,Investigation,Study,Event,Sample],Seek::Util.user_creatable_types
  end
end
