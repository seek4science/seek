require 'test_helper'

class JsonMetaTest < ActiveSupport::TestCase

  test "metadata contents" do
    contributor = Factory(:person,:orcid=>"0000-0002-1694-233X")
    item = Factory(:model_with_image,:description=>"model with an image",:policy=>Factory(:public_policy),:contributor=>contributor)
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]
    assert_equal "model with an image",json["description"]
    assert_equal 1,json["version"]
    json_contributor = json["contributor"]
    assert_equal contributor.name,json_contributor["name"]
    assert_equal "http://localhost:3000/people/#{contributor.id}",json_contributor["uri"]
    assert_equal "http://orcid.org/0000-0002-1694-233X",json_contributor["orcid"]

    assert_equal ["models/#{item.id}/cronwright.xml", "models/#{item.id}/file_picture.png"],json["contains"].sort
  end

  test "metadata contents for assay" do
    contributor = Factory(:person,:orcid=>"0000-0002-1694-233X")
    item = Factory(:experimental_assay,:description=>"my ro assay",:policy=>Factory(:public_policy),:contributor=>contributor)
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]
    assert_equal "my ro assay",json["description"]

    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type",json["assay_type_uri"]
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type",json["technology_type_uri"]

    json_contributor = json["contributor"]
    assert_equal contributor.name,json_contributor["name"]
    assert_equal "http://localhost:3000/people/#{contributor.id}",json_contributor["uri"]
    assert_equal "http://orcid.org/0000-0002-1694-233X",json_contributor["orcid"]
  end

end