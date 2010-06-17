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
    get :index,:id=>@object.id, :format=>"xml"
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
      parser.parse
    rescue LibXML::XML::Error=>e
      return false,"XML parse error: #{e.message}"
    end
    
    return true,""
  end
  
end