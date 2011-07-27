require 'test_helper'
require 'pubmed_query'

class PublicationTest < ActiveSupport::TestCase
  
  fixtures :all

  test "event association" do
    publication = publications(:one)
    assert publication.events.empty?
    event = events(:event_with_no_files)
    publication.events << event
    assert publication.valid?
    assert publication.save
    assert_equal 1, publication.events.count
  end

  test "assay association" do
    publication = publications(:pubmed_2)
    assay = assays(:modelling_assay_with_data_and_relationship)
    User.current_user = assay.contributor.user
    assay_asset = assay_assets(:metabolomics_assay_asset1)
    assert_not_equal assay_asset.asset, publication
    assert_not_equal assay_asset.assay, assay
    assay_asset.asset = publication
    assay_asset.assay = assay
    assay_asset.save!
    assay_asset.reload
    assert assay_asset.valid?
    assert_equal assay_asset.asset, publication
    assert_equal assay_asset.assay, assay

  end

  test "publication date from pubmed" do
    WebMock.allow_net_connect!
    query = PubmedQuery.new("seek","sowen@cs.man.ac.uk")
    result = query.fetch(21533085)
    assert_equal Date.parse("20 April 2011"),result.date_published

    sleep 0.5 #the sleeps are to keep in accordance to the pubmed service requirements
    result = query.fetch(1)
    assert_equal Date.parse("1 June 1975"),result.date_published

    sleep 0.5 #the sleeps are to keep in accordance to the pubmed service requirements
    result = query.fetch(20533085)
    assert_equal Date.parse("9 June 2010"),result.date_published
  end

  test "book chapter doi" do
    WebMock.allow_net_connect!
    query=DoiQuery.new("sowen@cs.man.ac.uk")
    result = query.fetch("10.1007/978-3-642-16239-8_8")
    assert_equal 3,result.publication_type
    assert_equal "Prediction with Confidence Based on a Random Forest Classifier",result.title
    assert_equal 2,result.authors.size
    last_names = ["Devetyarov","Nouretdinov"]
    result.authors.each do |auth|
      assert last_names.include? auth.last_name
    end
    
    assert_equal "Artificial Intelligence Applications and Innovations",result.journal
    assert_equal Date.parse("1 Jan 2010"),result.date_published
    assert_equal "10.1007/978-3-642-16239-8_8",result.doi

  end

  test "model and datafile association" do
    publication = publications(:pubmed_2)
    assert publication.related_models.include?(models(:teusink))
    assert publication.related_data_files.include?(data_files(:picture))
  end

  test "test uuid generated" do
    x = publications(:one)
    assert_nil x.attributes["uuid"]
    x.save    
    assert_not_nil x.attributes["uuid"]
  end

  test "sort by published_date" do
    assert_equal Publication.find(:all).sort_by { |p| p.published_date}.reverse, Publication.find(:all)
  end
  
  test "title trimmed" do
    x = publications(:one)
    x.title=" a pub"
    x.save!
    assert_equal("a pub",x.title)
  end

  test "validation" do
    asset=Publication.new :title=>"fred",:project=>projects(:sysmo_project),:doi=>"111"
    assert asset.valid?

    asset=Publication.new :title=>"fred",:project=>projects(:sysmo_project),:pubmed_id=>"111"
    assert asset.valid?

    asset=Publication.new :title=>"fred",:project=>projects(:sysmo_project)
    assert !asset.valid?

    asset=Publication.new :project=>projects(:sysmo_project),:doi=>"111"
    assert !asset.valid?

    asset=Publication.new :title=>"fred",:doi=>"111"
    assert !asset.valid?
  end
  
  test "creators order is returned in the order they were added" do
    p=Publication.new(:title=>"The meaining of life",:abstract=>"Chocolate",:pubmed_id=>"777",:project=>projects(:sysmo_project))
    p.save!
    assert_equal 0,p.creators.size
    
    p1=people(:modeller_person)
    p2=people(:fred)    
    p3=people(:aaron_person)
    p4=people(:pal)
    
    p.creators << p1
    p.creators << p2    
    p.creators << p3
    p.creators << p4
    
    p.save!
    
    assert_equal 4,p.creators.size
    assert_equal [p1,p2,p3,p4],p.creators
  end
  
  test "uuid doesn't change" do
    x = publications(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  def test_project_required
    p=Publication.new(:title=>"blah blah blah",:pubmed_id=>"123")
    assert !p.valid?
    p.project=projects(:sysmo_project)
    assert p.valid?
  end
  
end
