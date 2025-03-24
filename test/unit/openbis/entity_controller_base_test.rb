require 'test_helper'
require 'openbis_test_helper'

include SharingFormTestHelper

class EntityControllerBaseTest < ActionController::TestCase
  include AuthenticatedTestHelper

  class BaseTest < ApplicationController
    include Seek::Openbis::EntityControllerBase
  end

  def setup
    mock_openbis_calls
    FactoryBot.create :experimental_assay_class
    @controller = BaseTest.new
    @user = FactoryBot.create(:project_administrator)
    User.current_user = @user.user
    @project = @user.projects.first
    @endpoint = FactoryBot.create(:openbis_endpoint, project: @project)
  end

  test 'datasets_linked_to gets ids of openbis data sets linked to study and assay' do
    util = Seek::Openbis::SeekUtil.new

    assert_equal [], @controller.datasets_linked_to(nil)

    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(['20171002172401546-38', '20171002190934144-40',
                                                                       '20171004182824553-41'])

    datafiles = datasets.map { |ds| util.createObisDataFile({}, @user, OpenbisExternalAsset.build(ds)) }
    assert_equal 3, datafiles.length

    disable_authorization_checks do
      datafiles.each(&:save!)
    end

    linked = @controller.datasets_linked_to datafiles[0]
    assert_equal [], linked

    normaldf = FactoryBot.create :data_file, contributor:@user

    assay = FactoryBot.create :assay, contributor:@user

    assay.data_files << normaldf
    assay.data_files << datafiles[0]
    assay.data_files << datafiles[1]
    assay.save!

    linked = @controller.datasets_linked_to assay
    assert_equal 2, linked.length
    assert_equal ['20171004182824553-41', '20171002190934144-40'].sort, linked.sort

    study = assay.study
    assert study

    linked = @controller.datasets_linked_to study
    assert_equal 2, linked.length
    assert_equal ['20171004182824553-41', '20171002190934144-40'].sort, linked.sort
  end

  test 'get_zamples_linked_to gets ids of openbis zamples' do
    util = Seek::Openbis::SeekUtil.new

    assert_equal [], @controller.zamples_linked_to(nil)

    normalas = FactoryBot.create(:assay, contributor:@user)
    study = normalas.study

    assert_equal [], @controller.zamples_linked_to(normalas)
    assert_equal [], @controller.zamples_linked_to(study)
    assert_equal [], @controller.zamples_linked_to(FactoryBot.create(:data_file))

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])

    assay_params = { study_id: study.id }
    assays = zamples.map { |ds| util.createObisAssay(assay_params, @user, OpenbisExternalAsset.build(ds)) }
    assert_equal 2, assays.length

    disable_authorization_checks do
      assays.each(&:save!)
    end

    assert_equal [], @controller.zamples_linked_to(assays[0])

    study.reload

    assert_equal 3, study.assays.size

    linked = @controller.zamples_linked_to study
    assert_equal 2, linked.length
    assert_equal ['20171002172111346-37', '20171002172639055-39'].sort, linked.sort
  end
end
