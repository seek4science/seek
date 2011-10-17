require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    as_virtualliver do
      assert_equal [DataFile,Model,Presentation,Publication,Sop,Assay,Investigation,Study,Event,Sample,Specimen],Seek::Util.user_creatable_types
    end
  end
end
