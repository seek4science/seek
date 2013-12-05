require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    assert_equal [DataFile,Model,Presentation,Publication,Sop,Workflow,Assay,Investigation,Study,Event,Sample,Specimen,Strain],Seek::Util.user_creatable_types
  end

  test "authorized types" do
    assert_equal [Assay,DataFile,Event,Investigation,Model,Presentation,Publication,Sample,Sop,Specimen,Strain,Study,TavernaPlayer::Run,Workflow],Seek::Util.authorized_types
  end

  test "rdf capable types" do
    types = Seek::Util.rdf_capable_types
    assert types.include?(DataFile)
    assert !types.include?(Policy)
  end
end
