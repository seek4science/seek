require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    assert_equal [DataFile,Model,Presentation,Publication,Sop,Workflow,Assay,Investigation,Study,Event,Sample,Specimen,Strain],Seek::Util.user_creatable_types
  end

  test "authorized types" do
    expected =  [Assay,DataFile,Event,Investigation,Model,Presentation,Publication,Sample,Sop,Specimen,Strain,Study,Sweep,TavernaPlayer::Run,Workflow].collect(&:name)
    actual = Seek::Util.authorized_types.collect(&:name)
    assert_equal expected,actual
  end

  test "rdf capable types" do
    types = Seek::Util.rdf_capable_types
    assert types.include?(DataFile)
    assert !types.include?(Policy)
  end
end
