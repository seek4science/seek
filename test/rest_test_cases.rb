# mixin to automate testing of Rest services per controller test

require 'libxml'
require 'pp'
require 'json-schema'
require 'json-diff'

module RestTestCases
  XML_SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'xml', 'rest', 'schema-v1.xsd')
  JSONAPI_SCHEMA_FILE_PATH = File.join(Rails.root, 'public', '2010', 'json', 'rest', 'jsonapi-schema-v1')

  def index_schema_file_path
    File.join(Rails.root, 'public', '2010', 'json', 'rest',
              "index_#{@controller.controller_name}_200_response.json")
  end

  def get_schema_file_path
    File.join(Rails.root, 'public', '2010', 'json', 'rest',
              "get_#{@controller.controller_name}_200_response.json")
  end

  def definitions_path
    File.join(Rails.root, 'public', '2010', 'json', 'rest',
              'definitions.json')
  end

  def test_index_rest_api_xml
    check_for_xml_type_skip # some types do not support XML, only JSON

    # to make sure something in the database is created
    object = rest_api_test_object

    get :index, format: 'xml'
    perform_api_checks
  end

  def test_displays_correct_counts_in_index
    check_for_xml_type_skip # some types do not support XML, only JSON


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
    check_for_xml_type_skip # some types do not support XML, only JSON

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

  def validate_json (path)
    if File.readable?(path)
      errors = JSON::Validator.fully_validate_json(path, @response.body)
      unless errors.empty?
        msg = ""
        errors.each do |e|
          msg += e + "\n"
        end
        raise Minitest::Assertion, msg
      end
    end
  end

  def validate_json_against_fragment (fragment)
    if File.readable?(definitions_path)
      errors = JSON::Validator.fully_validate_json(definitions_path, @response.body, fragment: fragment)
      unless errors.empty?
        msg = ""
        errors.each do |e|
          msg += e + "\n"
        end
        raise Minitest::Assertion, msg
      end
    end
  end

  def test_show_json(object = rest_api_test_object)
    clz = @controller.controller_name.classify.constantize
    get :show, id: object, format: 'json'
    if check_for_501_read_return
      assert_response :not_implemented
    else
      perform_jsonapi_checks
      validate_json_against_fragment ("#/definitions/get#{@controller.class.name.sub('Controller', 'Response')}")
    end
  # rescue ActionController::UrlGenerationError
  #   skip("unable to test read JSON for #{clz}")
  end

  def test_index_json
    clz = @controller.controller_name.classify.constantize
    get :index, format: 'json'
    if check_for_501_index_return
      assert_response :not_implemented
    else
    perform_jsonapi_checks
    validate_json_against_fragment ("#/definitions/index#{@controller.class.name.sub('Controller', 'Response')}")
    end
  # rescue ActionController::UrlGenerationError
  #   skip("unable to test index JSON for #{clz}")
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

  def test_json_content
    check_for_json_type_skip
    ['min','max'].each do |m|
      object = get_test_object(m)
      json_file = File.join(Rails.root, 'public', '2010', 'json', 'content_compare',
                            "#{m}_#{@controller.controller_name.classify.downcase}.json")
      #parse such that backspace is eliminated and null turns to nil
      json_to_compare = JSON.parse(File.read(json_file))
      begin
        edit_max_object(object) if (m == 'max')
      rescue NoMethodError
      end

      get :show, id: object, format: 'json'
      assert_response :success
      parsed_response = JSON.parse(@response.body)
      puts parsed_response,"\n"
      check_content_diff(json_to_compare, parsed_response)
    end
  end

  def check_content_diff(json1, json2)
    plural_obj = @controller.controller_name.pluralize
    base = json2["data"]["meta"]["base_url"]
    diff = JsonDiff.diff(json1, json2)

    diff.reverse_each do |el|
      #the self link must start with the pluralized controller's name (e.g. /people)
      if (el["path"] =~ /self/)
        assert_match /^\/#{plural_obj}/, el["value"]
      # url in version, e.g.  base_url/data_files/877365356?version=1
      elsif (el["path"] =~ /versions\/\d+\/url/)
        assert_match /#{base}\/#{plural_obj}\/\d+\?version=\d+/, el["value"]
        diff.delete(el)
      # link in content blob, e.g.  base_url/data_files/877365356/content_blobs/343567275
      elsif (el["path"] =~ /content_blobs\/\d+\/link/)
        assert_match /#{base}\/#{plural_obj}\/\d+\/content_blobs\/\d+/, el["value"]
        diff.delete(el)
      elsif (el["path"] =~ /avatar/)
        assert_match /^\/#{plural_obj}\/\d+\/avatars\/\d+/, el["value"]
        diff.delete(el)
      end
    end

    diff.delete_if {
        |el| el["path"] =~ /\/id|person_responsible_id|created|updated|modified|uuid|jsonapi|self|md5sum|sha1sum/
    }

    assert_equal [], diff
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

  #skip if this current controller type doesn't support XML format
  def check_for_xml_type_skip
    clz = @controller.controller_name.classify.constantize.to_s
    if %w[Programme Sample SampleType ContentBlob].include?(clz)
      skip("skipping XML tests for #{clz}")
    end
  end

  #skip if this current controller type doesn't support JSON format
  def check_for_json_type_skip
    clz = @controller.controller_name.classify.constantize.to_s
    if %w[Sample SampleType Strain ContentBlob].include?(clz)
      skip("skipping JSONAPI tests for #{clz}")
    end
  end

  #check if this current controller type doesn't support read
  def check_for_501_read_return
    clz = @controller.controller_name.classify.constantize.to_s
    return %w[Sample SampleType Strain].include?(clz)
  end

  #check if this current controller type doesn't support index
  def check_for_501_index_return
    clz = @controller.controller_name.classify.constantize.to_s
    return %w[Sample Strain].include?(clz)
  end

  # m corresponds to 'min'/'max'
  def get_test_object(m)
    clz = @controller.controller_name.classify.downcase
    return Factory(("#{m}_#{clz}").to_sym)
  end
end
