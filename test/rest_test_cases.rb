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
    assert validate_xml_with_schema @response.body
  end
  
  def test_get_xml
    get :show,:id=>@object.id, :format=>"xml"    
    assert_response :success    
    valid,message = check_xml
    assert valid,message
    schema_happy = validate_xml_with_schema @response.body
    display_xml @response.body unless schema_happy
    assert schema_happy, "Failed to validate against schema"
  end
  
  def check_xml
    assert_equal 'application/xml', @response.content_type
    xml=@response.body
    return false,"XML is nil" if xml.nil?
    begin
      parser = LibXML::XML::Parser.string(xml,:encoding => LibXML::XML::Encoding::UTF_8)
      doc = parser.parse
      
      return false,"Could not find dcterms:created, which should be in all xml. Check its not using the old XML format" if doc.find("//dcterms:created","dcterms:http://purl.org/dc/terms/").empty?
    rescue LibXML::XML::Error=>e
      return false,"XML parse error: #{e.message}"
    end
    
    return true,""
    
  end  
  
  def validate_xml_with_schema(xml)       
    document = LibXML::XML::Document.string(xml)
    schema = LibXML::XML::Schema.new(SCHEMA_FILE_PATH)    
    result = document.validate_schema(schema) do |message,flag|
      puts ""
      puts "#{(flag ? 'ERROR' : 'WARNING')}: #{message}"
      puts ""      
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