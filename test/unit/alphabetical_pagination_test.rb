require File.dirname(__FILE__) + '/../test_helper'

class AlphabeticalPaginationTest < ActiveSupport::TestCase

  fixtures :all

  def setup
    Person.find(:all).each {|p| p.save! if p.valid?} #required to force the before_save callback to set the first_letter, we can ignore those that aren't valid
  end

  def test_first_letter

    p=Person.find_by_last_name("Aardvark")
    assert_not_nil p
    assert_not_nil p.first_letter
    assert_equal "A", p.first_letter

  end

  def test_paginate_no_options
    @people=Person.paginate
    assert @people.size>0
    assert_equal "A", @people.page
    assert_not_nil @people.page_totals
    assert_equal @people.size, @people.page_totals["A"]

    @people.each do |p|
      assert_equal "A", p.first_letter
    end
  end

  def test_paginate_by_page
    @people=Person.paginate :page=>"B"
    assert @people.size>0
    assert_equal "B", @people.page
    assert_equal @people.size, @people.page_totals["B"]
    @people.each do |p|
      assert_equal "B", p.first_letter
    end
  end

  def test_handle_oslash
    p=Person.new(:last_name=>"Øyvind", :email=>"sdfkjhsdfkjhsdf@email.com")
    assert p.save
    assert_equal "O", p.first_letter
  end

  def test_handle_umlaut
    p=Person.new(:last_name=>"Ümlaut", :email=>"sdfkjhsdfkjhsdf@email.com")
    assert p.save
    assert_equal "U", p.first_letter
  end

  def test_handle_accent
    p=Person.new(:last_name=>"Ýiggle", :email=>"sdfkjhsdfkjhsdf@email.com")
    assert p.save
    assert_equal "Y", p.first_letter    
  end

end