#mixin to automate testing of Rest services per controller test

require 'libxml'
require 'pp'

module RestTestCases

  SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'xml', 'rest', 'schema-v1.xsd')
  
  def test_index_rest_api_xml
    #to make sure something in the database is created
    object=rest_api_test_object

    get :index, :format=>"xml"
    perform_api_checks
  end

  def test_get_rest_api_xml object=rest_api_test_object
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
  
  def perform_api_checks
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