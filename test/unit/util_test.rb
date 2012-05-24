require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    assert_equal [DataFile,Model,Presentation,Publication,Sop,Assay,Investigation,Study,DataFileWithSample,Event,Sample],Seek::Util.user_creatable_types
  end

  test "authorized types" do
    assert_equal [Assay, DataFile, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Specimen, Strain, Study],Seek::Util.authorized_types
  end
end
