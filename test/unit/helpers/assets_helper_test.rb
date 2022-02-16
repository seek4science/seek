require 'test_helper'

class AssetsHelperTest < ActionView::TestCase
  def setup
    User.destroy_all
    assert User.all.blank?

    @project = Factory :project
    @user = Factory(:person,project:@project).user
  end

  test 'authorised assets' do
    @assets = create_a_bunch_of_assets
    with_auth_lookup_disabled do
      check_expected_authorised
    end
  end

  test 'form_submit_buttons' do
    new_study = Study.new

    @controller.action_name = 'new'
    html = form_submit_buttons(new_study)
    assert_match /submit_button_clicked\(true, true, 'study'\);/,html
    assert_match /id=\"study_submit_btn\"/,html

    html = form_submit_buttons(new_study, validate:false)
    assert_match /submit_button_clicked\(false, true, 'study'\);/,html

    html = form_submit_buttons(new_study, validate:false, preview_permissions:false)
    assert_match /submit_button_clicked\(false, false, 'study'\);/,html
  end

  test 'submit button text' do
    new_assay = Assay.new
    new_model = Model.new
    data_file = Factory(:data_file)
    investigation = Factory(:investigation)

    assert_equal t('submit_button.create'), submit_button_text(new_assay)
    assert_equal t('submit_button.upload'), submit_button_text(new_model)
    assert_equal t('submit_button.update'), submit_button_text(data_file)
    assert_equal t('submit_button.update'), submit_button_text(investigation)
  end

  test 'rendered_asset_view' do
    slideshare_url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794/'
    slideshare_api_url = "http://www.slideshare.net/api/oembed/2?url=#{slideshare_url}&format=json"
    mock_remote_file("#{Rails.root}/test/fixtures/files/slideshare.json",
                     slideshare_api_url,
                     'Content-Type' => 'application/json')

    person = Factory(:admin)
    User.current_user = person.user

    # show something for presentation
    pres = Factory(:presentation, policy: Factory(:public_policy))
    pres.content_blob.url = slideshare_url
    pres.content_blob.save!
    refute rendered_asset_view(pres).blank?

    # nothing  for private
    pres = Factory(:presentation, policy: Factory(:private_policy))
    pres.content_blob.url = slideshare_url
    pres.content_blob.save!
    assert rendered_asset_view(pres).blank?

    # nothing  for none slideshare
    pres = Factory(:presentation, policy: Factory(:public_policy))
    assert rendered_asset_view(pres).blank?
  end

  test 'authorised assets with lookup' do
    @assets = create_a_bunch_of_assets
    with_auth_lookup_enabled do
      assert_not_equal Sop.count, Sop.lookup_count_for_user(@user)
      assert !Sop.lookup_table_consistent?(@user.id)

      update_lookup_tables

      assert_equal DataFile.count, DataFile.lookup_count_for_user(@user.id)
      assert_equal Sop.count, Sop.lookup_count_for_user(@user.id)
      assert_equal Sop.count, Sop.lookup_count_for_user(@user)
      assert Sop.lookup_table_consistent?(@user.id)
      assert Sop.lookup_table_consistent?(nil)

      check_expected_authorised
    end
  end


  test 'request_contact_button_enabled?' do
    @owner = Factory(:max_person)
    presentation = Factory :ppt_presentation, contributor: @owner
    requester = Factory(:person, first_name: 'Aaron', last_name: 'Spiggle')
    sop = Factory(:sop, projects: [@project],contributor: nil)
    sop.contributor= nil

    with_config_value(:email_enabled,true) do
      User.with_current_user(requester.user) do
        assert request_contact_button_enabled?(presentation)
        refute request_contact_button_enabled?(sop)
      end

      User.with_current_user(nil) do
        refute request_contact_button_enabled?(presentation)
        refute request_contact_button_enabled?(sop)
      end
    end

    # no scenario will work without email enabled
    with_config_value(:email_enabled,false) do
      User.with_current_user(requester.user) do
        refute request_contact_button_enabled?(presentation)
        refute request_contact_button_enabled?(sop)
      end

      User.with_current_user(nil) do
        refute request_contact_button_enabled?(presentation)
        refute request_contact_button_enabled?(sop)
      end
    end

    # not if recently requested
    with_config_value(:email_enabled,true) do
      User.with_current_user(requester.user) do
        travel_to 16.hours.ago do
          ContactRequestMessageLog.create(subject:presentation,sender:requester)
        end
        assert request_contact_button_enabled?(presentation)
        travel_to 1.hour.ago do
          ContactRequestMessageLog.create(subject:presentation,sender:requester)
        end
        refute request_contact_button_enabled?(presentation)
      end
    end
  end



  def check_expected_authorised
    User.with_current_user(@user) do
      authorised = authorised_assets Sop
      assert_equal 4, authorised.count
      assert_equal %w(A B D E), authorised.collect(&:title).sort

      authorised = authorised_assets Sop, @project

      assert_equal 2, authorised.count
      assert_equal %w(B D), authorised.collect(&:title).sort

      authorised = authorised_assets Sop, Factory(:project)
      assert_empty authorised

      authorised = authorised_assets Sop, nil, 'manage'
      assert_equal 3, authorised.count
      assert_equal %w(A B D), authorised.collect(&:title).sort
    end


    User.with_current_user(nil) do
      authorised = authorised_assets Sop
      assert_equal 3, authorised.count
      assert_equal %w(A D E), authorised.collect(&:title).sort

      authorised = authorised_assets DataFile
      assert_equal 2, authorised.count
      assert_equal %w(A B), authorised.collect(&:title).sort
    end

    User.with_current_user(Factory(:user)) do
      authorised = authorised_assets DataFile, nil, 'download'
      assert_equal 2, authorised.count
      assert_equal %w(A B), authorised.collect(&:title).sort

      authorised = authorised_assets DataFile, @project, 'download'
      assert_equal 1, authorised.count
      assert_equal ['A'], authorised.collect(&:title)
    end
  end

  test 'add_new_item_to_options filters disabled' do
    publication = Factory(:publication)
    with_config_value(:data_files_enabled, true) do
      options = []
      add_new_item_to_options(publication) do |text, path|
        options << text
      end
      assert_includes options, "Add new #{t('data_file')}"
    end

    with_config_value(:data_files_enabled, false) do
      options = []
      add_new_item_to_options(publication) do |text, path|
        options << text
      end
      refute_includes options, "Add new #{t('data_file')}"
    end
  end

  private

  def update_lookup_tables
    @assets.each(&:update_lookup_table_for_all_users)
  end

  def create_a_bunch_of_assets
    other_person = Factory :person
    disable_authorization_checks do
      Sop.delete_all
      DataFile.delete_all
    end
    assert Sop.all.blank?
    assert DataFile.all.blank?
    assets = []
    assets << Factory(:sop, title: 'A', contributor: other_person, policy: Factory(:public_policy))
    assets << Factory(:sop, title: 'B', contributor: @user.person, policy: Factory(:private_policy))
    assets << Factory(:sop, title: 'C', contributor: other_person, policy: Factory(:private_policy))
    assets << Factory(:sop, title: 'D', contributor: @user.person, policy: Factory(:publicly_viewable_policy))
    assets << Factory(:sop, title: 'E', contributor: other_person, policy: Factory(:publicly_viewable_policy))
    assets << Factory(:data_file, title: 'A', contributor: @user.person, policy: Factory(:downloadable_public_policy))
    assets << Factory(:data_file, title: 'B', contributor: other_person, policy: Factory(:downloadable_public_policy))
    assets
  end
end
