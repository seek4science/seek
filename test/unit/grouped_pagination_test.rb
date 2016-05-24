#encoding: utf-8
require 'test_helper'

class GroupedPaginationTest < ActiveSupport::TestCase

  def test_first_letter
    p = Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
    assert_not_nil p.first_letter
    assert_equal "A", p.first_letter
  end
  
  def test_pages_accessor
    pages = Person.pages
    assert pages.length>1
    ("A".."Z").to_a.each{|letter| assert pages.include?(letter)}
  end
  
  def test_first_letter_ignore_space
    inv=Factory :investigation, :title=>" Inv"
    assert_equal "I",inv.first_letter
  end
  
  def test_latest_limit
    assert_equal Seek::Config.limit_latest,Person.latest_limit
    assert_equal Seek::Config.limit_latest,Project.latest_limit
    assert_equal Seek::Config.limit_latest,Institution.latest_limit
    assert_equal Seek::Config.limit_latest,Investigation.latest_limit
    assert_equal Seek::Config.limit_latest,Study.latest_limit
    assert_equal Seek::Config.limit_latest,Assay.latest_limit
    assert_equal Seek::Config.limit_latest,DataFile.latest_limit
    assert_equal Seek::Config.limit_latest,Model.latest_limit
    assert_equal Seek::Config.limit_latest,Sop.latest_limit
    assert_equal Seek::Config.limit_latest,Publication.latest_limit
    assert_equal Seek::Config.limit_latest,Event.latest_limit
    assert_equal Seek::Config.limit_latest,Strain.latest_limit
  end

  def test_paginate_no_options
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
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
    Factory :person, :last_name=>"Bobbins",:first_name=>"Fred"
    Factory :person, :last_name=>"Brown",:first_name=>"Fred"
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
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
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
    Factory :person, :last_name=>"Bobbins",:first_name=>"Fred"
    Factory :person, :last_name=>"Davis",:first_name=>"Fred"
    #delete those with A
    Person.where(["first_letter = ?","A"]).each {|p| p.delete }
    @people=Person.paginate :default_page=>"first"
    assert @people.size>0
    assert_equal "B",@people.page

    @people=Person.paginate :page=>"A"
    assert_equal 0,@people.size
    assert_equal "A",@people.page

    #delete every person, and check it still returns the first page with empty content
    Person.all.each{|x| x.delete}
    @people=Person.paginate :default_page=>"first"
    assert_equal 0,@people.size
    assert_equal "A",@people.page
    
  end

  def test_default_page_accessor    
    assert Person.default_page == "latest" || Person.default_page == "all"
  end

  def test_extra_condition_as_array_direct
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
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
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
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
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
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
    p1 = Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
    p2 = Factory :person, :last_name=>"Azbo",:first_name=>"John"
    @people=Person.paginate :page=>"A",:order=>"last_name ASC"
    assert @people.size>0
    assert_equal "A", @people.page
    assert_equal p1,@people.first

    @people=Person.paginate :page=>"A",:order=>"last_name DESC"
    assert @people.size>0
    assert_equal "A", @people.page
    assert_equal p2,@people.first
  end
  
  def test_show_all
    Factory :person, :last_name=>"Aardvark",:first_name=>"Fred"
    Factory :person, :last_name=>"Jones",:first_name=>"Fred"
    @people=Person.paginate :page=>"all"
    assert_equal Person.all.size, @people.size
  end
  
  def test_post_fetch_pagination
    user = Factory :user
    Factory :sop, :contributor=>user
    Factory :sop, :contributor=>user
    sops = Sop.all
    assert !sops.empty?
    sops.each {|s| User.current_user = s.contributor; s.save if s.valid?} #Set first letters
    result = Sop.paginate_after_fetch(sops)
    assert !result.empty? #Check there's something on the first page    
  end

  test "pagination for default page using rails-setting plugin" do
    @people=Person.paginate
    assert_equal @people.page, Seek::Config.default_page("people")
    @projects=Project.paginate
    assert_equal @projects.page, Seek::Config.default_page("projects")
    @institutions=Institution.paginate
    assert_equal @institutions.page, Seek::Config.default_pages[:institutions]
    @investigations=Investigation.paginate
    assert_equal @investigations.page, Seek::Config.default_pages[:investigations]
    @studies=Study.paginate
    assert_equal @studies.page, Seek::Config.default_pages[:studies]
    @assays=Assay.paginate
    assert_equal @assays.page, Seek::Config.default_pages[:assays]
    @data_files=DataFile.paginate
    assert_equal @data_files.page, Seek::Config.default_pages[:data_files]
    @models=Model.paginate
    assert_equal @models.page, Seek::Config.default_page("models")
    @sops=Sop.paginate
    assert_equal @sops.page, Seek::Config.default_pages[:sops]
    @publications=Publication.paginate
    assert_equal @publications.page, Seek::Config.default_pages[:publications]
    @events=Event.paginate
    assert_equal @events.page, Seek::Config.default_pages[:events]
  end

  test 'order by updated_at for -latest- pagination for all item types' do
    item_types = [:person, :project, :institution, :investigation, :study, :assay, :data_file, :model, :sop, :presentation, :publication,:event, :strain ]
    item_types.each do |type|
      item1 = Factory(type, :updated_at => 2.second.ago)
      item2 = Factory(type, :updated_at => 1.second.ago)

      klass = type.to_s.camelize.constantize
      latest_items = klass.paginate_after_fetch(klass.default_order, :page=>'latest')
      assert latest_items.index(item2) < latest_items.index(item1)
    end
  end

  test 'order by published_date for publications, for -all- and -alphabet- pagnation' do
    publication1 = Factory(:publication, :title => 'AB', :published_date => 2.days.ago)
    publication2 = Factory(:publication, :title => 'AC', :published_date => 1.days.ago)

    all_items = Publication.paginate_after_fetch(Publication.default_order, :page=>'all')
    assert all_items.index(publication2) < all_items.index(publication1)

    pageA_items = Publication.paginate_after_fetch(Publication.default_order, :page=>'A')
    assert pageA_items.index(publication2) < pageA_items.index(publication1)
  end

  test 'order by start_date for events, for -all- and -alphabet- pagnation' do
    event1 = Factory(:event, :title => 'AB', :start_date => 2.days.ago)
    event2 = Factory(:event, :title => 'AC', :start_date => 1.days.ago)

    all_items = Event.paginate_after_fetch(Event.default_order, :page=>'all')
    assert all_items.index(event2) < all_items.index(event1)

    pageA_items = Event.paginate_after_fetch(Event.default_order, :page=>'A')
    assert pageA_items.index(event2) < pageA_items.index(event1)
  end

  test 'order by title for projects and institutions, for -all- and -alphabet- pagnation' do
    yellow_pages = [:project, :institution]
    yellow_pages.each do |type|
      item1 = Factory(type, :title => 'AB', :updated_at => 2.days.ago)
      item2 = Factory(type, :title => 'AC', :updated_at => 1.days.ago)

      klass = type.to_s.camelize.constantize
      all_items = klass.paginate_after_fetch(klass.default_order, :page=>'all')
      assert all_items.index(item1) < all_items.index(item2)

      pageA_items = klass.paginate_after_fetch(klass.default_order, :page=>'A')
      assert pageA_items.index(item1) < pageA_items.index(item2)
    end
  end

  test 'order by title for the rest of item types,  for -all- and -alphabet- pagnation' do
    item_types = [:investigation, :study, :assay, :data_file, :model, :sop, :presentation, :strain]
    item_types.each do |type|
      item1 = Factory(type, :title => 'AB', :updated_at => 2.days.ago)
      item2 = Factory(type, :title => 'AC', :updated_at => 1.days.ago)

      klass = type.to_s.camelize.constantize
      all_items = klass.paginate_after_fetch(klass.default_order, :page=>'all')
      assert all_items.index(item1) < all_items.index(item2)

      pageA_items = klass.paginate_after_fetch(klass.default_order, :page=>'A')
      assert pageA_items.index(item1) < pageA_items.index(item2)
    end
  end

end