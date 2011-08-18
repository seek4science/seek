require File.dirname(__FILE__) + '/test_helper.rb'

class ConfigTest < ActiveSupport::TestCase
  def setup
    Annotations::Config.reset
    Annotations::Config.attribute_names_for_values_to_be_downcased.concat([ "downcased_thing" ])
    Annotations::Config.attribute_names_for_values_to_be_upcased.concat([ "upcased_thing" ])
    Annotations::Config.strip_text_rules.update({ "tag" => [ '"', ',' ], "comma_stripped" => ',', "regex_strip" => /\d/ })
    Annotations::Config.limits_per_source.update({ "rating" => 1 })
    Annotations::Config.attribute_names_to_allow_duplicates.concat([ "allow_duplicates_for_this" ])
    Annotations::Config.content_restrictions.update({ "rating" => { :in => 1..5, :error_message => "Please provide a rating between 1 and 5" },
                                                    "category" => { :in => [ "fruit", "nut", "fibre" ], :error_message => "Please select a valid category" } })
    Annotations::Config.default_attribute_identifier_template = "http://x.com/attribute#%s"
    Annotations::Config.attribute_name_transform_for_identifier = Proc.new { |name|
      regex = /\.|-|:/
      if name.match(regex)
        name.gsub(regex, ' ').titleize.gsub(' ', '').camelize(:lower)
      else
        name.camelize(:lower)
      end
    }
  end
  
  def teardown
    Annotations::Config.reset
  end
  
  def test_values_downcased_or_upcased
    source = users(:jane)
    
    # Should downcase

    ann1 = Annotation.create(:attribute_name => "downcased_thing", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann1.valid?
    assert_equal "unique", ann1.value_content
    
    # Should upcase
    
    ann2 = Annotation.create(:attribute_name => "upcased_thing", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann2.valid?
    assert_equal "UNIQUE", ann2.value_content
    
    # Should not do anything
    
    ann3 = Annotation.create(:attribute_name => "dont_do_anything", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann3.valid?
    assert_equal "UNIque", ann3.value_content
  end
  
  def test_strip_text_rules
    source = users(:john)
    
    # Strip 'tag'
    
    ann1 = Annotation.create(:attribute_name => "Tag", 
                             :value => 'v,al"ue', 
                             :source_type => source.class.name, 
                             :source_id => source.id,
                             :annotatable_type => "Book",
                             :annotatable_id => 1)
    
    assert ann1.valid?
    assert_equal "value", ann1.value_content
    
    # Strip 'comma_stripped'
    
    ann2 = Annotation.create(:attribute_name => "comma_stripped", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann2.valid?
    assert_equal 'val"ue', ann2.value_content
    
    # Regexp strip

    ann3 = Annotation.create(:attribute_name => "regex_strip", 
                            :value => 'v1,al"ue23x4', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann3.valid?
    assert_equal 'v,al"uex', ann3.value_content

    # Don't strip!
    
    ann4 = Annotation.create(:attribute_name => "dont_strip", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann4.valid?
    assert_equal 'v,al"ue', ann4.value_content
  end
  
  def test_limits_per_source
    source = users(:john)
    
    bk1 = Book.create
    
    ann1 = bk1.annotations << Annotation.new(:attribute_name => "rating", 
                                    :value => NumberValue.new(:number => 4), 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann1
    assert_equal 4, bk1.annotations(true)[0].value_content
    assert_equal 1, bk1.annotations(true).length
    
    ann2 = Annotation.new(:attribute_name => "rating", 
                          :value => 1, 
                          :source_type => source.class.name, 
                          :source_id => source.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk1.id)
    
    assert ann2.invalid?
    assert !ann2.save
    assert_equal 1, bk1.annotations(true).length
    
    ann3 = bk1.annotations(true)[0]
    ann3.value = 3
    assert ann3.valid?
    assert ann3.save
    assert_equal 1, bk1.annotations(true).length
    
    # Check that two versions of the annotation now exist
    assert_equal 2, bk1.annotations[0].versions.length
  end
  
  def test_attribute_names_to_allow_duplicates
    source = users(:john)
    
    # First test the default case of not allowing duplicates...
    
    bk1 = Book.create
    
    ann1 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann1
    assert_equal 1, bk1.annotations.length
    
    ann2 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there again", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann2
    assert_equal 2, bk1.annotations(true).length
    
    ann3 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_equal false, ann3
    assert_equal 2, bk1.annotations(true).length
    
    
    # Then test the configured exceptions to the default rule...
    
    bk2 = Book.create
    
    ann4 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann4
    assert_equal 1, bk2.annotations.length
    
    ann5 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there again", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann5
    assert_equal 2, bk2.annotations(true).length
    
    ann6 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann6
    assert_equal 3, bk2.annotations(true).length
  end
  
  def test_content_restrictions
    source1 = users(:john)
    source2 = users(:jane)
    
    # First test the default case of not restricting values...
    
    bk1 = Book.create
    
    ann1 = Annotation.new(:attribute_name => "allow_any_value", 
                          :value => "Hello there", 
                          :source_type => source1.class.name, 
                          :source_id => source1.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk1.id)
    
    assert ann1.valid?
    assert ann1.save
    assert_equal 1, bk1.annotations.length
    
    
    # Then test the configured exceptions to the default rule...
    
    bk2 = Book.create
    
    ann2 = Annotation.new(:attribute_name => "rating", 
                          :value => "2", 
                          :source_type => source1.class.name, 
                          :source_id => source1.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk2.id)
    
    assert ann2.valid?
    assert ann2.save
    assert_equal 1, bk2.annotations.length
    
    
    ann3 = Annotation.new(:attribute_name => "rating", 
                          :value => "10", 
                          :source_type => source2.class.name, 
                          :source_id => source2.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk2.id)
    
    assert ann3.invalid?
    assert !ann3.save
    assert ann3.errors.full_messages.include?("Please provide a rating between 1 and 5")
    assert_equal 1, bk2.annotations(true).length
    
    
    ann4 = Annotation.new(:attribute_name => "category", 
                          :value => "fibre", 
                          :source_type => source1.class.name, 
                          :source_id => source1.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk2.id)
    
    assert ann4.valid?
    assert ann4.save
    assert_equal 2, bk2.annotations(true).length
    
    ann5 = Annotation.new(:attribute_name => "category", 
                          :value => "home cooking", 
                          :source_type => source2.class.name, 
                          :source_id => source2.id,
                          :annotatable_type => "Book",
                          :annotatable_id => bk2.id)
    
    assert ann5.invalid?
    assert !ann5.save
    assert ann5.errors.full_messages.include?("Please select a valid category")
    assert_equal 2, bk2.annotations(true).length
  end

  def test_default_attribute_identifier_template
    attrib1 = AnnotationAttribute.create(:name => "myAttribute")
    assert attrib1.valid?
    assert_equal "http://x.com/attribute#myAttribute", attrib1.identifier

    attrib2 = AnnotationAttribute.create(:name => "http://www.example.org/annotations#details")
    assert attrib2.valid?
    assert_equal "http://www.example.org/annotations#details", attrib2.identifier

    attrib3 = AnnotationAttribute.create(:name => "<www.example.org/annotations#details>")
    assert attrib3.valid?
    assert_equal "www.example.org/annotations#details", attrib3.identifier

    attrib4 = AnnotationAttribute.create(:name => "hello_world-attribute:zero")
    assert attrib4.valid?
    assert_equal "http://x.com/attribute#helloWorldAttributeZero", attrib4.identifier
  end
end