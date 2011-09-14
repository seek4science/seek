require 'test_helper'

class AnnotationsTest < ActiveSupport::TestCase

  #this test currently fails - requires update to latest plugin and use fo factory
  test "reuses text value for same value and attribute" do
    return puts "AnnotationsTest skipped - awaiting update to latest plugin"
    df=Factory :data_file
    sop=Factory :sop,:contributor=>df.contributor
    User.with_current_user df.contributor do
      a=Annotation.new(:source => df.contributor,
                      :annotatable => df,
                      :attribute_name => "tag",
                      :value => "fred")

      assert_difference("TextValue.count") do
        a.save!
      end

      a2=Annotation.new(:source => Factory(:person),
                      :annotatable => sop,
                      :attribute_name => "tag",
                      :value => "fred")

      assert_no_difference("TextValue.count") do
        a2.save!
      end
    end
  end
  

end