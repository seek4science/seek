#mixin to automate testing of Rest services per controller test

require 'libxml'
require 'pp'

module RestTestCases

  SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'xml', 'rest', 'schema-v1.xsd')
  
  def test_index_rest_api_xml
    skip("currently skipping REST API tests") if skip_rest_tests?
    #to make sure something in the database is created
    object=rest_api_test_object

    get :index, :format=>"xml"
    perform_api_checks
  end

  def test_get_rest_api_xml object=rest_api_test_object
    skip("currently skipping REST API tests") if skip_rest_tests?
    get :show,:id=>object, :format=>"xml"
    perform_api_checks

    #check the title, due to an error with it being incorrectly described
    if object.respond_to?(:title)
      xml = @response.body
      doc = LibXML::XML::Document.string(xml)

      title = doc.find("//dc:title",["dc:http://purl.org/dc/elements/1.1/"]).first
      assert_not_nil title
      assert_equal object.title,title.content
    end
  end

  def test_response_code_for_not_accessible_xml
    clz = @controller.controller_name.classify.constantize
    if clz.respond_to?(:authorization_supported?) && clz.authorization_supported?
      itemname = @controller.controller_name.singularize.underscore
      item = Factory itemname.to_sym, :policy => Factory(:private_policy)

      logout
      get :show,:id=>item.id,:format=>"xml"
      assert_response :forbidden
    end
  end

  def test_response_code_for_not_available_xml
    clz = @controller.controller_name.classify.constantize
    id = 9999
    while (!clz.find_by_id(id).nil?)
      id += 1
    end

    logout
    get :show,:id=>id,:format=>"xml"
    assert_response :not_found
  end
  
  def perform_api_checks
    skip("currently skipping REST API tests") if skip_rest_tests?
    assert_response :success    
    valid,message = check_xml
    assert valid,message        
    validate_xml_against_schema(@response.body)
  end
  
  def check_xml
    assert_equal 'application/xml', @response.content_type
    xml=@response.body
    return false,"XML is nil" if xml.nil?
    
    return true,""    
  end  
  
  def validate_xml_against_schema(xml,schema=SCHEMA_FILE_PATH)       
    document = LibXML::XML::Document.string(xml)
    schema = LibXML::XML::Schema.new(schema)
    result = true
    begin
      document.validate_schema(schema)
    rescue LibXML::XML::Error => e
      result = false            
      assert false,"Error validating against schema: #{e.message}"
    end
  
    return result
  end
  
  def display_xml xml
    x=1
    xml.split("\n").each do |line|
      puts "#{x} #{line}"
      x=x+1
    end
  end
  
end