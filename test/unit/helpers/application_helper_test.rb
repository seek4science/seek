require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  test 'persistent_resource_id' do
    with_config_value(:application_name,"TEST-TEST-TEST") do

      assay = Factory(:assay)
      html = persistent_resource_id(assay)
      blocks=HTML::Document.new(html).root.children.first.children
      # should be something like
      # <p class="id">
      #   <label>TEST-TEST-TEST ID: </label>
      #   <a href="http://test.host/assays/1035386651">http://test.host/assays/1035386651</a>
      # </p>
      assert_equal 'label',blocks.first.name
      assert_match(/TEST-TEST-TEST ID/,blocks.first.children.first.content)
      assert_equal 'a',blocks.last.name
      assert_match(/http:\/\/test.host\/assays\/#{assay.id}/,blocks.last['href'])
      assert_match(/http:\/\/test.host\/assays\/#{assay.id}/,blocks.last.children.first.content)

      versioned_sop=Factory(:sop_version)
      html = persistent_resource_id(versioned_sop)
      blocks=HTML::Document.new(html).root.children.first.children
      # should be something like
      # <p class="id">
      #   <label>TEST-TEST-TEST ID: </label>
      #   <a href="http://test.host/sops/1055250457?version=2">http://test.host/sops/1055250457?version=2</a>
      # </p>
      assert_equal 'label',blocks.first.name
      assert_match(/TEST-TEST-TEST ID/,blocks.first.children.first.content)
      assert_equal 'a',blocks.last.name
      assert_match(/http:\/\/test.host\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/,blocks.last['href'])
      assert_match(/http:\/\/test.host\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/,blocks.last.children.first.content)
    end
  end

  def test_join_with_and
    assert_equal "a, b and c",join_with_and(["a","b","c"])
    assert_equal "a",join_with_and(["a"])
    assert_equal "a, b, c and d",join_with_and(["a","b","c","d"])
    assert_equal "a and b",join_with_and(["a","b"])
    assert_equal "a: b: c and d",join_with_and(["a","b","c","d"],": ")
  end

  test "instance of resource_type" do
    m = instance_of_resource_type("model")
    assert m.is_a?(Model)
    assert m.new_record?

    p = instance_of_resource_type("Presentation")
    assert p.is_a?(Presentation)
    assert p.new_record?

    assert_nil instance_of_resource_type(nil)
    assert_nil instance_of_resource_type("mushypeas")
    assert_nil instance_of_resource_type({})

  end

  test "force to treat 1 Jan as year only" do
    date = Date.new(2012,1,1)
    text = date_as_string(date,false,true)
    assert_equal "2012",text

    date = Date.new(2012,2,1)
    text = date_as_string(date,false,true)
    assert_equal "1st Feb 2012",text

    date = Date.new(2012,1,2)
    text = date_as_string(date,false,true)
    assert_equal "2nd Jan 2012",text
  end

  test "seek stylesheet tag" do
    with_config_value :css_appended,"fish" do
      with_config_value :css_prepended,"apple" do
        tags = seek_stylesheet_tags "carrot"
        assert_include tags,"<link href=\"/stylesheets/prepended/apple.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
        assert_include tags,"<link href=\"/stylesheets/carrot.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
        assert_include tags,"<link href=\"/stylesheets/appended/fish.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
        assert tags.index("fish.css") > tags.index("carrot.css")
        assert tags.index("carrot.css") > tags.index("apple.css")
        refute_equal 0,tags.index("apple.css")
      end

    end
  end

  test "seek javascript tag" do
    with_config_value :javascript_appended,"fish" do
      with_config_value :javascript_prepended,"apple" do
        tags = seek_javascript_tags "carrot"
        assert_include tags,"<script src=\"/javascripts/prepended/apple.js\" type=\"text/javascript\"></script>"
        assert_include tags,"<script src=\"/javascripts/carrot.js\" type=\"text/javascript\"></script>"
        assert_include tags,"<script src=\"/javascripts/appended/fish.js\" type=\"text/javascript\"></script>"
        assert tags.index("fish.js") > tags.index("carrot.js")
        assert tags.index("carrot.js") > tags.index("apple.js")
        refute_equal 0,tags.index("apple.js")
      end

    end
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
    assert_equal "28th Oct 2011",date_as_string(date)

    date = Date.new(2011,10,28)
    assert_equal "28th Oct 2011",date_as_string(date)

    date = Time.parse("2011-10-28")
    assert_equal "28th Oct 2011",date_as_string(date)
  end

  test "date_as_string with nil date" do
    assert_equal "<span class='none_text'>No date defined</span>",date_as_string(nil)
  end

  test "resource tab title" do
    assert_equal "EBI Biomodels",internationalized_resource_name("EBI Biomodels",true)
    assert_equal "Database",internationalized_resource_name("Database",false)
    assert_equal I18n.t('model').pluralize,internationalized_resource_name("Model")
    assert_equal I18n.t('data_file').pluralize,internationalized_resource_name("DataFile")
    assert_equal I18n.t('data_file').pluralize,internationalized_resource_name("DataFiles")
    assert_equal I18n.t('data_file'),internationalized_resource_name("DataFile",false)
    assert_equal I18n.t('sop').pluralize,internationalized_resource_name("SOP")
    assert_equal I18n.t('sop').pluralize,internationalized_resource_name("Sop")
    assert_equal I18n.t('sop'),internationalized_resource_name("Sop",false)
  end

  test 'using_docker?' do
    path = Seek::Docker::FLAG_FILE_PATH
    assert_equal path,File.join(Rails.root,'config','using-docker')
    begin
      refute File.exists?(path)
      refute using_docker?
      FileUtils.touch(path)
      assert using_docker?
    rescue
        raise e
    ensure
      File.delete(path)
      refute File.exists?(path)
    end
  end

end