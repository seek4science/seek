require 'test_helper'

class PresentationTest < ActiveSupport::TestCase
  test 'validations' do
    presentation = Factory :presentation
    presentation.title = ''

    assert !presentation.valid?

    presentation.reload

    # VL only:allow no projects
    as_virtualliver do
      presentation.projects.clear
      assert presentation.valid?
    end
  end

  test "new presentation's version is 1" do
    presentation = Factory :presentation
    assert_equal 1, presentation.version
  end

  test 'can create new version of presentation' do
    presentation = Factory :presentation
    old_attrs = presentation.attributes

    disable_authorization_checks do
      presentation.save_as_new_version('new version')
    end

    assert_equal 1, old_attrs['version']
    assert_equal 2, presentation.version

    old_attrs.delete('version')
    new_attrs = presentation.attributes
    new_attrs.delete('version')

    old_attrs.delete('updated_at')
    new_attrs.delete('updated_at')

    old_attrs.delete('created_at')
    new_attrs.delete('created_at')

    assert_equal old_attrs, new_attrs
  end

  test 'event association' do
    presentation = Factory :presentation
    assert presentation.events.empty?

    User.current_user = presentation.contributor
    assert_difference 'presentation.events.count' do
      presentation.events << Factory(:event)
    end
  end

  test 'has uuid' do
    presentation = Factory :presentation
    assert_not_nil presentation.uuid
  end

  test 'is restorable after destroy' do
    pre = Factory :presentation, policy: Factory(:all_sysmo_viewable_policy), title: 'is it restorable?'
    blob_path = pre.content_blob.filepath
    User.current_user = pre.contributor
    assert_difference('Presentation.count', -1) do
      pre.destroy
    end
    assert_nil Presentation.find_by_title 'is it restorable?'
    assert_difference('Presentation.count', 1) do
      disable_authorization_checks { Presentation.restore_trash!(pre.id) }
    end
    pre = Presentation.find_by_title('is it restorable?')
    refute_nil pre
    refute_nil pre.content_blob
    assert_equal blob_path, pre.content_blob.filepath
    assert File.exist?(blob_path)
  end
end
