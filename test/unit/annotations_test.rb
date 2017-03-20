require 'test_helper'

class AnnotationsTest < ActiveSupport::TestCase
  test 'versioning of annotations should be disabled' do
    df = Factory :data_file
    sop = Factory :sop, contributor: df.contributor
    User.with_current_user df.contributor do
      a = Annotation.new(source: df.contributor,
                         annotatable: df,
                         attribute_name: 'tag',
                         value: 'fred')
      assert_difference('Annotation.count', 1) do
        assert_no_difference('TextValue::Version.count') do
          assert_no_difference('Annotation::Version.count') do
            a.save!
          end
        end
      end
    end
  end
end
