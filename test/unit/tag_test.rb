require 'test_helper'

class TagTest < ActiveSupport::TestCase
  fixtures :all

  test "tag ownership" do
    s=sops(:my_first_sop)
    User.with_current_user(s.contributor) do
      assert s.tags.empty?, "This sop should have no tags for this test to work"

      u1=users(:quentin)
      u2=users(:aaron)

      assert s.tags_from(u2).empty?
      assert s.tags_from(u1).empty?

      u1.tag(s,:with=>"one, two",:on=>:tags)
      s.reload

      assert_equal ["one","two"],s.tag_counts.collect{|t| t.name}.sort
      assert_equal ["one","two"],s.tags_from(u1).sort
      assert s.tags_from(u2).empty?

      u2.tag(s,:with=>"two, three",:on=>:tags)

      s.reload

      assert_equal ["one","three","two"],s.tag_counts.collect{|t| t.name}.sort
      assert_equal ["one","two"],s.tags_from(u1).sort
      assert_equal ["three","two"],s.tags_from(u2).sort
    end
  end

  test "overall ownership" do
    tag = tags(:fishing)
    assert_equal 1,tag.overall_total

    tag = tags(:golf)
    assert_equal 2,tag.overall_total
  end
  
end