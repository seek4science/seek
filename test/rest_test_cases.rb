#mixin to automate testing of Rest services per controller test

require 'libxml'
require 'pp'

module RestTestCases

  SCHEMA_FILE_PATH = File.join(RAILS_ROOT, 'public', '2010', 'xml', 'rest', 'schema-v1.xsd')
  
  def test_index_xml
    get :index, :format=>"xml"
    assert_response :success

    valid,message = check_xml
    assert valid,message
    validate_xml_against_schema(@response.body)
  end

  def test_get_xml object=@object
    get :show,:id=>object, :format=>"xml"
    perform_api_checks
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