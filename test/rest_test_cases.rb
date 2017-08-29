# mixin to automate testing of Rest services per controller test

require 'libxml'
require 'pp'
require 'json-schema'

module RestTestCases
  XML_SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'xml', 'rest', 'schema-v1.xsd')
  JSONAPI_SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'json', 'rest', 'jsonapi-schema-v1')

  def test_index_rest_api_xml
    clz = @controller.controller_name.classify.constantize.to_s
    if (clz == 'SampleType' || clz == 'Sample')
      skip('skipping XML tests for Sample and SampleType')
    end
    # to make sure something in the database is created
    object = rest_api_test_object

    get :index, format: 'xml'
    perform_api_checks
  end

  def test_displays_correct_counts_in_index
    clz = @controller.controller_name.classify.constantize.to_s
    if (clz == 'SampleType' || clz == 'Sample')
      skip('skipping XML tests for Sample and SampleType')
    end

    # to make sure something in the database is created
    object = rest_api_test_object

    get :index, format: 'xml'

    xml = @response.body
    doc = LibXML::XML::Document.string(xml)

    total = doc.find('//seek:statistics/seek:total', ['seek:http://www.sysmo-db.org/2010/xml/rest']).first.content.to_i
    assert_equal object.class.count, total

    if object.class.respond_to?(:all_authorized_for)
      actual_hidden = object.class.count - object.class.all_authorized_for('view', User.current_user).count
    else
      actual_hidden = object.class.count - (object.class.respond_to?(:default_order) ? object.class.default_order : object.class.all).count
    end

    hidden = doc.find('//seek:statistics/seek:hidden', ['seek:http://www.sysmo-db.org/2010/xml/rest']).first.content.to_i
    assert_equal actual_hidden, hidden
  end

  def test_get_rest_api_xml(object = rest_api_test_object)
    clz = @controller.controller_name.classify.constantize.to_s
    if (clz == 'SampleType' || clz == 'Sample')
      skip('skipping XML tests for Sample and SampleType')
    end
    get :show, id: object, format: 'xml'
    perform_api_checks

    # check the title, due to an error with it being incorrectly described
    if object.respond_to?(:title)
      xml = @response.body
      doc = LibXML::XML::Document.string(xml)

      title = doc.find('//dc:title', ['dc:http://purl.org/dc/elements/1.1/']).first
      assert_not_nil title
      assert_equal object.title, title.content
    end
  end

  def test_show_json(object = rest_api_test_object)
    get :show, id: object, format: 'json'
    perform_jsonapi_checks
  end

  def test_index_json
    object = rest_api_test_object
    get :index, format: 'json'
    perform_jsonapi_checks
  end

  def test_response_code_for_not_accessible
    clz = @controller.controller_name.classify.constantize
    if clz.respond_to?(:authorization_supported?) && clz.authorization_supported?
      itemname = @controller.controller_name.singularize.underscore
      item = Factory itemname.to_sym, policy: Factory(:private_policy)
      logout
      ['xml', 'json'].each do |format|
        get :show, id: item.id, format: format
        assert_response :forbidden
      end
    end
  end

  def test_response_code_for_not_available
    clz = @controller.controller_name.classify.constantize
    id = 9999
    id += 1 until clz.find_by_id(id).nil?

    logout
    ['xml', 'json'].each do |format|
      get :show, id: id, format: format
      assert_response :not_found
    end
  end

  def perform_api_checks
    assert_response :success
    valid, message = check_xml
    assert valid, message
    validate_xml_against_schema(@response.body)
  end

  def perform_jsonapi_checks
    assert_response :success
    assert_equal 'application/vnd.api+json', @response.content_type
    #puts JSON::Validator.fully_validate(JSONAPI_SCHEMA_FILE_PATH, @response.body)
    assert JSON::Validator.validate(JSONAPI_SCHEMA_FILE_PATH, @response.body)

  end

  def check_xml
    assert_equal 'application/xml', @response.content_type
    xml = @response.body
    return false, 'XML is nil' if xml.nil?

    [true, '']
  end

  def validate_xml_against_schema(xml, schema = XML_SCHEMA_FILE_PATH)
    skip('currently skipping REST API schema check') if skip_rest_schema_check?
    document = LibXML::XML::Document.string(xml)
    schema = LibXML::XML::Schema.new(schema)
    result = true
    begin
      document.validate_schema(schema)
    rescue LibXML::XML::Error => e
      result = false
      assert false, "Error validating against schema: #{e.message}"
    end

    result
  end

  def display_xml(xml)
    x = 1
    xml.split("\n").each do |line|
      puts "#{x} #{line}"
      x += 1
    end
  end
end
