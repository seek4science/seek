require 'test_helper'

class SampleCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Sample
  end

  def populate_extra_attributes(hash)
    extra_attributes = {}
    title = hash.dig('data', 'attributes', 'attribute_map', 'the_title')
    extra_attributes[:title] = title if title
    extra_attributes.with_indifferent_access
  end

  def setup
    admin_login

    @sample = Factory(:sample, contributor: current_person, policy: Factory(:public_policy))

    @project = Factory(:min_project)
    @project.title = 'testProject'

    institution = Factory(:institution)
    current_person.add_to_project_and_institution(@project, institution)
    @sample_type = SampleType.new(title: "vahidSampleType", project_ids: [@project.id], contributor: current_person)
    @sample_type.sample_attributes << Factory(:sample_attribute, title: 'the_title', is_title: true, required: true, sample_attribute_type: Factory(:string_sample_attribute_type), sample_type: Factory(:simple_sample_type))
    @sample_type.sample_attributes << Factory(:sample_attribute, title: 'a_real_number', sample_attribute_type: Factory(:float_sample_attribute_type), required: false, sample_type: @sample_type)
    @sample_type.save!
  end

  test 'patching a couple of attributes retains others' do
    admin_login
    sample = Factory(:patient_sample, contributor: current_person, policy: Factory(:public_policy))
    params = {
      "data": {
        "type": "samples",
        "id": "#{sample.id}",
        "attributes": {
          "attribute_map": {
            "full name": "Jack Frost",
            "weight": 12.4,
            "postcode": "Z50 8GG"
          }
        }
      }
    }
    assert_no_difference('Sample.count') do
      patch sample_path(sample.id, format: :json), params: params, as: :json
    end

    assert_response :success
    sample = Sample.find(sample.id)
    assert_equal "Jack Frost", sample.get_attribute_value("full name")
    assert_equal 12.4, sample.get_attribute_value("weight")
    assert_equal "Z50 8GG", sample.get_attribute_value("postcode")
    assert_equal 44, sample.get_attribute_value("age")
  end

  test 'patching a couple of attributes retains others including capitals' do
    admin_login
    User.current_user = @current_user
    sample = Factory(:max_sample, contributor: current_person, policy: Factory(:public_policy))
    params = {
      "data": {
        "type": "samples",
        "id": "#{sample.id}",
        "attributes": {
          "attribute_map": {
            "full_name": "Jack Frost",
            'CAPITAL key': 'some value',
            "postcode": "Z50 8GG"
          }
        }
      }
    }
    assert_no_difference('Sample.count') do
      patch sample_path(sample.id, format: :json), params: params, as: :json
    end

    assert_response :success
    sample = Sample.find(sample.id)
    assert_equal "Jack Frost", sample.get_attribute_value("full_name")
    assert_equal "Z50 8GG", sample.get_attribute_value("postcode")
    assert_equal 'HD', sample.get_attribute_value("address")
    assert_equal "some value", sample.get_attribute_value("CAPITAL key")
  end

  test 'set sample_type and attributes in post' do
    admin_login
    patient_sample_type = Factory(:patient_sample_type)
    params = {
      "data": {
        "type": "samples",
        "attributes": {
          "title": "Jack Frost",
          "attribute_map": {
            "full name": "Jack Frost",
            "weight": 12.4,
            "age": 12
          }
        },
        "relationships": {
          "projects": {
            "data":
              [
                {
                  "type": "projects",
                  "id": "#{current_person.projects.first.id}"
                }
              ]
          },
          "sample_type": {
            "data": {
              "id": "#{patient_sample_type.id}",
              "type": "sample_types"
            }
          }
        }
      }
    }
    assert_difference('Sample.count') do
      post samples_path(format: :json), params: params, as: :json
    end
    assert_response :success
    sample = Sample.last
    assert_equal patient_sample_type, sample.sample_type
    assert_equal "Jack Frost", sample.get_attribute_value("full name")
    assert_equal 12.4, sample.get_attribute_value("weight")
    assert_equal 12, sample.get_attribute_value("age")
  end
end
