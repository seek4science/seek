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
    assert_equal "A",p.first_letter
  end

  def test_paginate_no_options
    @people=Person.paginate    
    assert @people.size>0
    @people.each do |p|
      assert_equal "A",p.first_letter
    end
  end

end