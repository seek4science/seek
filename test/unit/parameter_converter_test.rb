require 'test_helper'

class ParameterConverter < ActiveSupport::TestCase

  setup do
    @converter = Seek::Api::ParameterConverter.new('test')
  end

  test 'restructures JSON-API style request params into Rails style params' do
    params = ActionController::Parameters.new(
        type: 'test',
        data: {
            attributes: { title: 'hello' },
            relationships: {
                related: {
                    data: [
                        { type: 'related', id: 1 },
                        { type: 'related', id: 2 }
                    ]
                }
            }
        }
    )

    new_params = @converter.convert(params.dup)

    assert new_params.key?(:test)
    assert_equal 'hello', new_params[:test][:title]
    assert_equal [1, 2], new_params[:test][:related_ids].sort,
                 'Relationships should be converted into the form: `<relationship>_ids`'
    refute new_params.key?(:data)
  end

  test 'renames parameters' do
    params = ActionController::Parameters.new(
        type: 'test',
        data: {
            attributes: { programme_ids: [] },
        }
    )

    new_params = @converter.convert(params.dup)

    refute new_params[:test].key?(:programme_ids)
    assert new_params[:test].key?(:programme_id)
  end

  test 'converts assay/tech type parameters' do
    params = ActionController::Parameters.new(
        type: 'test',
        data: {
            attributes: {
                technology_type: { uri: 'http://example.com/tech' },
                assay_type: { uri: 'http://example.com/assay' }
            },
        }
    )

    new_params = @converter.convert(params.dup)

    assert_equal 'http://example.com/tech', new_params[:test][:technology_type_uri]
    assert_equal 'http://example.com/assay', new_params[:test][:assay_type_uri]
  end

  test 'elevates and converts content blob parameters' do
    params = ActionController::Parameters.new(
        type: 'test',
        data: {
            attributes: {
                content_blobs: [
                    { url: 'http://example.com/content1' },
                    { url: 'http://example.com/content2' },
                ]
            },
        }
    )

    new_params = @converter.convert(params.dup)

    refute new_params[:test].key?(:content_blobs)
    assert_equal 'http://example.com/content1', new_params[:content_blobs][0][:data_url]
    assert_equal 'http://example.com/content2', new_params[:content_blobs][1][:data_url]
  end

  test 'converts assay class parameters' do
    params = ActionController::Parameters.new(
        type: 'test',
        data: { attributes: { assay_class: { key: 'EXP' } } }
    )

    bad_params = ActionController::Parameters.new(
        type: 'test',
        data: { attributes: { assay_class: { key: 'BANANANA' } } }
    )

    exp_class_id = AssayClass.where(key: 'EXP').first_or_create.id
    assert exp_class_id

    new_good_params = @converter.convert(params.dup)
    new_bad_params = @converter.convert(bad_params.dup)
    assert_equal exp_class_id, new_good_params[:test][:assay_class_id]
    assert_nil new_bad_params[:test][:assay_class_id]
  end
end

