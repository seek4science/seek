#mixin to automate testing of Rest services per controller test

require 'libxml'

module RestTestCases
  
  def test_index_xml
    get :index, :format=>"xml"
    assert_response :success
    
    valid,message = check_xml
    assert valid,message
  end
  
  def test_get_xml
    get :show,:id=>@object.id, :format=>"xml"
    puts @response.body
    assert_response :success    
    valid,message = check_xml
    assert valid,message
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
  
end