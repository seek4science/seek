require 'test_helper'

class SopsAnnotationTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper

  fixtures :all

  tests SopsController

  test "update tags with ajax only applied when viewable" do
    login_as(:aaron)
    user=users(:aaron)
    sop=sops(:sop_with_fully_public_policy)
    assert sop.tag_counts.empty?,"This should have no tags for this test to work"
    golf_tags=tags(:golf)

    assert_difference("ActsAsTaggableOn::Tagging.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>sop.id,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf_tags.id]}
    end

    sop.reload

    assert_equal ["golf"],sop.tag_counts.collect(&:name)

    sop=sops(:private_sop)
    assert sop.tag_counts.empty?,"This should have no tags for this test to work"

    assert !sop.can_view?(user),"Aaron should not be able to view this item for this test to be valid"

    assert_no_difference("ActsAsTaggableOn::Tagging.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>sop.id,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf_tags.id]}
    end

    sop.reload

    assert sop.tag_counts.empty?,"This should still have no tags"

  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    sop = Factory :sop,:contributor=>p.user


    assert sop.annotations.empty?,"this sop should have no tags for the test"

    golf = Factory :tag,:annotatable=>sop,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>sop,:source=>p2.user,:value=>"sparrow"

    sop.reload

    assert_equal ["golf","sparrow"],sop.annotations.collect{|a| a.value.text}.sort
    assert_equal [],sop.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>sop,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.id]}

    sop.reload

    assert_equal ["golf","soup","sparrow"],sop.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],sop.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "should update sop tags" do
    p = Factory :person
    sop=Factory :sop,:contributor=>p
    dummy_sop = Factory :sop

    login_as p.user
    assert sop.annotations.empty?,"Should have no annotations"
    Factory :tag,:source=>p.user,:annotatable=>sop,:value=>"fish"
    Factory :tag,:source=>p.user,:annotatable=>sop,:value=>"apple"
    golf = Factory :tag, :source=>p.user, :annotatable=>dummy_sop, :value=>"golf"

    sop.reload
    assert_equal ["apple","fish"],sop.annotations.collect{|a| a.value.text}.sort

    put :update, :id => sop, :tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.id],:sop=>{}, :sharing=>valid_sharing
    sop.reload

    assert_equal ["golf","soup"],sop.annotations.collect{|a| a.value.text}.sort
  end

  test "should update sop tags with correct ownership" do
    p1=Factory :person
    p2=Factory :person
    p3=Factory :person

    sop = Factory :sop,:contributor=>p1

    assert sop.annotations.empty?, "This sop should have no tags"

    login_as p1.user

    Factory :tag,:source=>p1.user,:annotatable=>sop,:value=>"fish"
    Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"fish"
    golf = Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"golf"
    Factory :tag,:source=>p3.user,:annotatable=>sop,:value=>"apple"

    sop.reload

    assert_equal ["fish"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}
    assert_equal ["fish","golf"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort
    assert_equal ["apple"],sop.annotations.select{|a|a.source==p3.user}.collect{|a| a.value.text}
    assert_equal ["apple","fish","golf"],sop.annotations.collect{|a| a.value.text}.uniq.sort

    put :update, :id => sop, :tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.id],:sop=>{}, :sharing=>valid_sharing
    sop.reload

    assert_equal ["soup"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}
    assert_equal ["golf"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort
    assert_equal [],sop.annotations.select{|a|a.source==p3.user}.collect{|a| a.value.text}
    assert_equal ["golf","soup"],sop.annotations.collect{|a| a.value.text}.uniq.sort

  end

  test "should update sop tags with correct ownership2" do
    #a specific case where a tag to keep was added by both the owner and another user.
    #Test checks that the correct tag ownership is preserved.

    p1=Factory :person
    p2=Factory :person

    sop = Factory :sop,:contributor=>p1

    assert sop.annotations.empty?, "This sop should have no tags"

    login_as p1.user

    Factory :tag,:source=>p1.user,:annotatable=>sop,:value=>"fish"
    golf = Factory :tag,:source=>p1.user,:annotatable=>sop,:value=>"golf"
    Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"apple"
    Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"golf"

    sop.reload

    assert_equal ["fish","golf"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["apple","golf"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    put :update, :id => sop, :tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.id],:sop=>{}, :sharing=>valid_sharing
    sop.reload

    assert_equal ["golf"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "update tags with known tags passed as unrecognised" do
    #checks that when a known tag is incorrectly passed as a new tag, it is correctly handled
    #this can happen when a tag is typed in full, rather than relying on autocomplete, and can affect the correct preservation of ownership

    p1=Factory :person
    p2=Factory :person

    sop = Factory :sop,:contributor=>p1

    assert sop.annotations.empty?, "This sop should have no tags"

    login_as p1.user

    fish = Factory :tag,:source=>p1.user,:annotatable=>sop,:value=>"fish"
    golf = Factory :tag,:source=>p1.user,:annotatable=>sop,:value=>"golf"
    Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"fish"
    Factory :tag,:source=>p2.user,:annotatable=>sop,:value=>"soup"

    sop.reload

    assert_equal ["fish","golf"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["fish","soup"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    put :update, :id => sop, :tag_autocompleter_unrecognized_items=>["fish"],:tag_autocompleter_selected_ids=>[golf.id],:sop=>{}, :sharing=>valid_sharing

    sop.reload

    assert_equal ["fish","golf"],sop.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["fish"],sop.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

end