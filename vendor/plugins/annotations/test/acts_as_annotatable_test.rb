require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsAnnotatableTest < ActiveSupport::TestCase
  
  def test_has_many_annotations_association
    assert_equal 6, books(:h).annotations.length
    assert_equal 5, books(:r).annotations.length
    assert_equal 2, chapters(:bh_c10).annotations.length
    assert_equal 4, chapters(:br_c2).annotations.length
  end
  
  def test_find_annotations_for_class_method
    assert_equal 6, Book.find_annotations_for(books(:h).id).length
    assert_equal 6, Book.find_annotations_for(books(:h).id, true).length
    assert_equal 5, Book.find_annotations_for(books(:r).id).length
    assert_equal 5, Book.find_annotations_for(books(:r).id, true).length
    assert_equal 2, Chapter.find_annotations_for(chapters(:bh_c10).id).length
    assert_equal 2, Chapter.find_annotations_for(chapters(:bh_c10).id, true).length
    assert_equal 4, Chapter.find_annotations_for(chapters(:br_c2).id).length
    assert_equal 4, Chapter.find_annotations_for(chapters(:br_c2).id, true).length
  end
  
  def test_find_annotations_by_class_method
    assert_equal 4, Book.find_annotations_by("User", users(:jane)).length
    assert_equal 4, Book.find_annotations_by("User", users(:jane), true).length
    assert_equal 1, Book.find_annotations_by("Group", groups(:sci_fi_geeks)).length
    assert_equal 1, Book.find_annotations_by("Group", groups(:sci_fi_geeks), true).length
    assert_equal 3, Chapter.find_annotations_by("User", users(:john)).length
    assert_equal 3, Chapter.find_annotations_by("User", users(:john), true).length
    assert_equal 2, Chapter.find_annotations_by("Group", groups(:classical_fans)).length
    assert_equal 2, Chapter.find_annotations_by("Group", groups(:classical_fans), true).length
  end
  
  def test_annotatable_name_field_class_attribute
    h = books(:h)
    
    hs = Book.find(:all, :conditions => { Book.annotatable_name_field.to_sym => h.title })
    
    assert !hs.empty?
  end
  
  def test_annotatable_name_instance_method
    assert_equal "Learning Ruby in 2 Seconds", books(:r).annotatable_name
    assert_equal "Hashing It Up", chapters(:br_c2).annotatable_name
  end
  
  def test_latest_annotations_instance_method
    assert_equal 6, books(:h).latest_annotations.length
    assert_equal 6, books(:h).latest_annotations(nil, true).length
    assert_equal 2, chapters(:bh_c10).latest_annotations.length
    assert_equal 2, chapters(:bh_c10).latest_annotations(nil, true).length
    
    assert_equal 2, books(:h).latest_annotations(2).length
    assert_equal 2, books(:h).latest_annotations(2, true).length
  end
  
  def test_annotations_with_attribute_instance_method
    assert_equal 2, books(:h).annotations_with_attribute("tag").length
    assert_equal 2, books(:h).annotations_with_attribute("tag", true).length
    assert_equal 0, books(:r).annotations_with_attribute("doesnt_exist").length
    assert_equal 0, books(:r).annotations_with_attribute("doesnt_exist", true).length
    assert_equal 1, chapters(:bh_c10).annotations_with_attribute("endingType").length
    assert_equal 1, chapters(:bh_c10).annotations_with_attribute("endingType", true).length
    assert_equal 1, chapters(:br_c202).annotations_with_attribute("Title").length
    assert_equal 1, chapters(:br_c202).annotations_with_attribute("Title", true).length
  end
  
  def test_annotations_with_attributes_instance_method
    assert_equal 4, books(:h).annotations_with_attributes([ "tag", "summary", "LENGTH" ]).length
    assert_equal 4, books(:h).annotations_with_attributes([ "tag", "summary", "LENGTH" ], true).length
    assert_equal 0, books(:h).annotations_with_attributes([ "doesnt_exist", "also doesn't exist" ]).length
    assert_equal 0, books(:h).annotations_with_attributes([ "doesnt_exist", "also doesn't exist" ], true).length
    assert_equal 1, chapters(:bh_c10).annotations_with_attributes([ "endingType" ]).length
    assert_equal 1, chapters(:bh_c10).annotations_with_attributes([ "endingType" ], true).length
    assert_equal 2, chapters(:br_c202).annotations_with_attributes([ "Title", "complexity", "doesn't exist but still"]).length
    assert_equal 2, chapters(:br_c202).annotations_with_attributes([ "Title", "complexity", "doesn't exist but still"], true).length
  end
  
  def test_annotations_with_attribute_and_by_source_instance_method
    assert_equal 1, books(:h).annotations_with_attribute_and_by_source("tag", users(:jane)).length
    assert_equal 1, books(:h).annotations_with_attribute_and_by_source("tag", users(:jane), true).length
    assert_equal 0, books(:r).annotations_with_attribute_and_by_source("doesnt_exist", users(:jane)).length
    assert_equal 0, books(:r).annotations_with_attribute_and_by_source("doesnt_exist", users(:jane), true).length
    assert_equal 1, chapters(:bh_c10).annotations_with_attribute_and_by_source("endingType", groups(:sci_fi_geeks)).length
    assert_equal 1, chapters(:bh_c10).annotations_with_attribute_and_by_source("endingType", groups(:sci_fi_geeks), true).length
    assert_equal 1, chapters(:br_c202).annotations_with_attribute_and_by_source("Title", users(:john)).length
    assert_equal 1, chapters(:br_c202).annotations_with_attribute_and_by_source("Title", users(:john), true).length
  end
  
  def test_all_annotations_excluding_attributes
    assert_equal 4, books(:h).all_annotations_excluding_attributes([ "TITLE", "length" ]).length
    assert_equal 4, books(:h).all_annotations_excluding_attributes([ "TITLE", "length" ], true).length
    assert_equal 5, books(:r).all_annotations_excluding_attributes([ "doesnt_exist" ]).length
    assert_equal 5, books(:r).all_annotations_excluding_attributes([ "doesnt_exist" ], true).length
    assert_equal 1, chapters(:bh_c10).all_annotations_excluding_attributes([ "endingType" ]).length
    assert_equal 1, chapters(:bh_c10).all_annotations_excluding_attributes([ "endingType" ], true).length
    assert_equal 2, chapters(:br_c202).all_annotations_excluding_attributes([ "tag", "doesn't exist but who cares" ]).length
    assert_equal 2, chapters(:br_c202).all_annotations_excluding_attributes([ "tag", "doesn't exist but who cares" ], true).length
  end
  
  def test_count_annotations_by_instance_method
    assert_equal 6, books(:h).count_annotations_by("all")
    assert_equal 2, books(:h).count_annotations_by("Group")
    assert_equal 4, chapters(:br_c2).count_annotations_by("All")
    assert_equal 3, chapters(:br_c2).count_annotations_by("User")
  end
  
  def test_create_annotations_instance_method
    bk = Book.create
    
    data1 = {
      :test1 => "test123",
      "test2" => nil,
      "  test3" => "",
      :foo => 1,
      :bar => [ "one", "two", 3, "", nil ]
    }

    anns1 = bk.create_annotations(data1, users(:jane))

    assert_equal 5, anns1.length
    anns1.each do |a|
      assert_kind_of Annotation, a
    end
    assert_equal 5, bk.annotations.length


    data2 = { :tagx => "ko", :tagy => [ "oii", "tuo" ] }

    anns2 = bk.create_annotations(data2, users(:jane))

    assert_equal 3, anns2.length
    anns2.each do |a|
      assert_kind_of Annotation, a
    end
    assert_equal 8, bk.annotations(true).length


    data3 = { :tagx => "ko", :tagy => [ "oii", "piopjpjnp" ] }

    anns3 = bk.create_annotations(data3, users(:jane))

    assert_equal 1, anns3.length
    anns2.each do |a|
      assert_kind_of Annotation, a
    end
    assert_equal 9, bk.annotations(true).length
  end
  
  def test_adding_of_annotation
    ch = chapters(:bh_c10)
    assert_equal 2, ch.annotations.length
    ann1 = Annotation.new(:attribute_id => AnnotationAttribute.find_or_create_by_name("tag").id, 
                          :source_type => "User", 
                          :source_id => 1)
    ann1.value = "test"
    ch.annotations << ann1
                          
    ann2 = Annotation.new(:attribute_name => "description", 
                          :source_type => "User", 
                          :source_id => 2)
    ann2.value = "test2"
    ch.annotations << ann2
                                           
    assert_not_nil(ann1)
    assert_not_nil(ann2)
    assert_equal 4, ch.annotations(true).length
  end

  def test_annotations_hash_method
    book1 = books(:h)
    expected_hash1 = {
      "Summary" => "Something interesting happens",
      "length" => 345,
      "Title" => "Harry Potter and the Exploding Men's Locker Room",
      "Tag" => [ "wizadry", "amusing rhetoric" ],
      "rating" => "4/5"
    }
    assert_equal expected_hash1, book1.annotations_hash

    book2 = Book.create(:title => "YAB")
    expected_hash2 = { }
    assert_equal expected_hash2, book2.annotations_hash
  end
  
end
