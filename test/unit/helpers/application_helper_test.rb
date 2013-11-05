require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  
  def test_join_with_and
    
    assert_equal "a, b and c",join_with_and(["a","b","c"])
    assert_equal "a",join_with_and(["a"])
    assert_equal "a, b, c and d",join_with_and(["a","b","c","d"])
    assert_equal "a and b",join_with_and(["a","b"])
    assert_equal "a: b: c and d",join_with_and(["a","b","c","d"],": ")
  end

  test "force to treat 1 Jan as year only" do
    date = Date.new(2012,1,1)
    text = date_as_string(date,false,true)
    assert_equal "2012",text

    date = Date.new(2012,2,1)
    text = date_as_string(date,false,true)
    assert_equal "1st February 2012",text

    date = Date.new(2012,1,2)
    text = date_as_string(date,false,true)
    assert_equal "2nd January 2012",text
  end

  test "should handle nil date" do
    text = date_as_string(nil)
    assert_equal "<span class='none_text'>No date defined</span>",text

    text = date_as_string(nil,false,true)
    assert_equal "<span class='none_text'>No date defined</span>",text

    text = date_as_string(nil,true,true)
    assert_equal "<span class='none_text'>No date defined</span>",text

  end

  test 'showing local time instead of GMT/UTC for date_as_string' do
    sop = Factory(:sop)
    created_at = sop.created_at

    assert created_at.utc?
    assert created_at.gmt?

    local_created_at = created_at.localtime
    assert !local_created_at.utc?
    assert !local_created_at.gmt?

    assert date_as_string(created_at, true).include?(local_created_at.strftime('%H:%M'))
  end

  test "date_as_string with Date or DateTime" do
    date = DateTime.parse("2011-10-28")
    assert_equal "28th October 2011",date_as_string(date)

    date = Date.new(2011,10,28)
    assert_equal "28th October 2011",date_as_string(date)

    date = Time.parse("2011-10-28")
    assert_equal "28th October 2011",date_as_string(date)
  end

  test "date_as_string with nil date" do
    assert_equal "<span class='none_text'>No date defined</span>",date_as_string(nil)
  end

  test "resource tab title" do
    assert_equal "EBI Biomodels",resource_tab_item_name("EBI Biomodels",true)
    assert_equal "Database",resource_tab_item_name("Database",false)
    assert_equal I18n.t('model').pluralize,resource_tab_item_name("Model")
    assert_equal I18n.t('data_file').pluralize,resource_tab_item_name("DataFile")
    assert_equal I18n.t('data_file').pluralize,resource_tab_item_name("DataFiles")
    assert_equal I18n.t('data_file'),resource_tab_item_name("DataFile",false)
    assert_equal I18n.t('sop').pluralize,resource_tab_item_name("SOP")
    assert_equal I18n.t('sop').pluralize,resource_tab_item_name("Sop")
    assert_equal I18n.t('sop'),resource_tab_item_name("Sop",false)
  end
end