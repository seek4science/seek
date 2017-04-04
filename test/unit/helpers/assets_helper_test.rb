require 'test_helper'

class AssetsHelperTest < ActionView::TestCase
  def setup
    User.destroy_all
    assert User.all.blank?
    @user = Factory :user
    @project = Factory :project
  end

  test 'authorised assets' do
    @assets = create_a_bunch_of_assets
    with_auth_lookup_disabled do
      check_expected_authorised
    end
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

  def check_expected_authorised
    User.current_user = @user
    authorised = authorised_assets Sop
    assert_equal 4, authorised.count
    assert_equal %w(A B D E), authorised.collect(&:title).sort

    authorised = authorised_assets Sop, @project
    assert_equal 1, authorised.count
    assert_equal 'A', authorised.first.title

    authorised = authorised_assets Sop, @user.person.projects
    assert_equal 1, authorised.count
    assert_equal 'E', authorised.first.title

    authorised = authorised_assets Sop, nil, 'manage'
    assert_equal 3, authorised.count
    assert_equal %w(A B D), authorised.collect(&:title).sort

    User.current_user = nil
    authorised = authorised_assets Sop
    assert_equal 3, authorised.count
    assert_equal %w(A D E), authorised.collect(&:title).sort

    User.current_user = Factory(:user)
    authorised = authorised_assets DataFile, nil, 'download'
    assert_equal 2, authorised.count
    assert_equal %w(A B), authorised.collect(&:title).sort

    authorised = authorised_assets DataFile, @project, 'download'
    assert_equal 1, authorised.count
    assert_equal ['B'], authorised.collect(&:title)

    User.current_user = nil
    authorised = authorised_assets DataFile
    assert_equal 2, authorised.count
    assert_equal %w(A B), authorised.collect(&:title).sort
  end

  private

  def update_lookup_tables
    @assets.each(&:update_lookup_table_for_all_users)
  end

  def create_a_bunch_of_assets
    other_user = Factory :user
    disable_authorization_checks do
      Sop.delete_all
      DataFile.delete_all
    end
    assert Sop.all.blank?
    assert DataFile.all.blank?
    assets = []
    assets << Factory(:sop, title: 'A', contributor: other_user, policy: Factory(:public_policy), projects: [@project])
    assets << Factory(:sop, title: 'B', contributor: @user, policy: Factory(:private_policy))
    assets << Factory(:sop, title: 'C', contributor: other_user, policy: Factory(:private_policy))
    assets << Factory(:sop, title: 'D', contributor: @user, policy: Factory(:publicly_viewable_policy))
    assets << Factory(:sop, title: 'E', contributor: other_user, policy: Factory(:publicly_viewable_policy), projects: @user.person.projects)

    assets << Factory(:data_file, title: 'A', contributor: @user, policy: Factory(:downloadable_public_policy))
    assets << Factory(:data_file, title: 'B', contributor: other_user, policy: Factory(:downloadable_public_policy), projects: [@project, Factory(:project)])
    assets
  end
end
