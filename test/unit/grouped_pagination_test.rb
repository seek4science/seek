require 'test_helper'

class GroupedPaginationTest < ActiveSupport::TestCase

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
  
  def test_pages_accessor
    pages = Person.pages
    assert pages.length>1
    ("A".."Z").to_a.each{|letter| assert pages.include?(letter)}
  end
  
  def test_first_letter_ignore_space
    inv=Investigation.new(:title=>" Inv",:project=>projects(:sysmo_project))
    inv.save!    
    assert_equal "I",inv.first_letter
  end
  
  def test_latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Person.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Project.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Institution.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Investigation.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Study.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Assay.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,DataFile.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Model.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Sop.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Publication.latest_limit
    assert_equal PAGINATE_LATEST_LIMIT,Event.latest_limit
  end

  def test_paginate_no_options    
    @people=Person.paginate :default_page=>"first"
    assert_equal(("A".."Z").to_a, @people.pages)
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
    assert_equal(("A".."Z").to_a, @people.pages)
    assert @people.size>0
    assert_equal "B", @people.page
    assert_equal @people.size, @people.page_totals["B"]    
    @people.each do |p|
      assert_equal "B", p.first_letter
    end
  end

  def test_sql_injection
    @people=Person.paginate :page=>"A or first_letter='B'"
    assert_equal 0,@people.size
    assert_equal(("A".."Z").to_a, @people.pages)
    assert_equal "A or first_letter='B'", @people.page
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

  def test_extra_conditions_as_array
    @people=Person.paginate :page=>"A",:conditions=>["last_name = ?","Aardvark"]
    assert_equal 1,@people.size
    assert(@people.page_totals.select do |k, v|
      k!="A" && v>0
    end.empty?,"All of the page totals should be 0")

    @people=Person.paginate :page=>"B",:conditions=>["last_name = ?","Aardvark"]
    assert_equal 0,@people.size
    assert_equal 1,@people.page_totals["A"]
  end

  #should jump to the first page that has content if :page=> isn't defined. Will use first page if no content is available
  def test_jump_to_first_page_with_content
    #delete those with A
    Person.find(:all,:conditions=>["first_letter = ?","A"]).each {|p| p.destroy }    
    @people=Person.paginate :default_page=>"first"
    assert @people.size>0
    assert_equal "B",@people.page

    @people=Person.paginate :page=>"A"
    assert_equal 0,@people.size
    assert_equal "A",@people.page

    #delete every person, and check it still returns the first page with empty content
    Person.find(:all).each{|x| x.destroy}
    @people=Person.paginate :default_page=>"first"
    assert_equal 0,@people.size
    assert_equal "A",@people.page
    
  end

  def test_default_page_accessor    
    assert Person.default_page == "latest" || Person.default_page == "all"
  end

  def test_extra_condition_as_array_direct
    @people=Person.paginate :page=>"A",:conditions=>["last_name = 'Aardvark'"]
    assert_equal 1,@people.size
    assert(@people.page_totals.select do |k, v|
      k!="A" && v>0
    end.empty?,"All of the page totals should be 0")

    @people=Person.paginate :page=>"B",:conditions=>["last_name = 'Aardvark'"]
    assert_equal 0,@people.size
    assert_equal 1,@people.page_totals["A"]

  end

  def test_extra_condition_as_string
    @people=Person.paginate :page=>"A",:conditions=>"last_name = 'Aardvark'"
    assert_equal 1,@people.size
    assert(@people.page_totals.select do |k, v|
      k!="A" && v>0
    end.empty?,"All of the page totals should be 0")

    @people=Person.paginate :page=>"B",:conditions=>"last_name = 'Aardvark'"
    assert_equal 0,@people.size
    assert_equal 1,@people.page_totals["A"]

  end

  def test_condition_as_hash
    @people=Person.paginate :page=>"A",:conditions=>{:last_name=>"Aardvark"}
    assert_equal 1,@people.size
    assert(@people.page_totals.select do |k, v|
      k!="A" && v>0
    end.empty?,"All of the page totals should be 0")

    @people=Person.paginate :page=>"B",:conditions=>{:last_name => "Aardvark"}
    assert_equal 0,@people.size
    assert_equal 1,@people.page_totals["A"]
  end

  def test_order_by
    @people=Person.paginate :page=>"A",:order=>"last_name ASC"
    assert @people.size>0
    assert_equal "A", @people.page
    assert_equal people(:person_for_default_page),@people.first

    @people=Person.paginate :page=>"A",:order=>"last_name DESC"
    assert @people.size>0
    assert_equal "A", @people.page
    assert_equal people(:person_for_pagination_order_test),@people.first
  end
  
  def test_show_all
    @people=Person.paginate :page=>"all"
    assert_equal Person.all.size, @people.size
  end
  
  def test_post_fetch_pagination
    sops = Sop.all
    sops.each {|s| s.save! if s.valid?} #Set first letters
    result = Sop.paginate_after_fetch(sops)
    assert !result.empty? #Check there's something on the first page    
  end

  test "pagination for default page" do
    configpath=File.join(RAILS_ROOT,"config/paginate.yml")
    config=YAML::load_file(configpath)
    @people=Person.paginate
    assert_equal @people.page, config["people"]["index"]
    @projects=Project.paginate
    assert_equal @projects.page, config["projects"]["index"]
    @institutions=Institution.paginate
    assert_equal @institutions.page, config["institutions"]["index"]
    @investigations=Investigation.paginate
    assert_equal @investigations.page, config["investigations"]["index"]
    @studies=Study.paginate
    assert_equal @studies.page, config["studies"]["index"]
    @assays=Assay.paginate
    assert_equal @assays.page, config["assays"]["index"]
    @data_files=DataFile.paginate
    assert_equal @data_files.page, config["data_files"]["index"]
    @models=Model.paginate
    assert_equal @models.page, config["models"]["index"]
    @sops=Sop.paginate
    assert_equal @sops.page, config["sops"]["index"]
    @publications=Publication.paginate
    assert_equal @publications.page, config["publications"]["index"]
    @events=Event.paginate
    assert_equal @events.page, config["events"]["index"]

  end

  test "pagination for default page using rails-setting plugin" do
    @people=Person.paginate
    assert_equal @people.page, Settings.index[:people]
    @projects=Project.paginate
    assert_equal @projects.page, Settings.index[:projects]
    @institutions=Institution.paginate
    assert_equal @institutions.page, Settings.index[:institutions]
    @investigations=Investigation.paginate
    assert_equal @investigations.page, Settings.index[:investigations]
    @studies=Study.paginate
    assert_equal @studies.page, Settings.index[:studies]
    @assays=Assay.paginate
    assert_equal @assays.page, Settings.index[:assays]
    @data_files=DataFile.paginate
    assert_equal @data_files.page, Settings.index[:data_files]
    @models=Model.paginate
    assert_equal @models.page, Settings.index[:models]
    @sops=Sop.paginate
    assert_equal @sops.page, Settings.index[:sops]
    @publications=Publication.paginate
    assert_equal @publications.page, Settings.index[:publications]
    @events=Event.paginate
    assert_equal @events.page, Settings.index[:events]

  end

end