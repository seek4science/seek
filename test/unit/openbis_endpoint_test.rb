require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @seek_util = Seek::Openbis::SeekUtil.new
  end

  test 'validation' do
    project = FactoryBot.create(:project)
    endpoint = OpenbisEndpoint.new project: project, username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60

    assert endpoint.valid?
    endpoint.username = nil
    refute endpoint.valid?
    endpoint.username = 'fred'
    assert endpoint.valid?

    endpoint.password = nil
    refute endpoint.valid?
    endpoint.password = '12345'
    assert endpoint.valid?

    endpoint.space_perm_id = nil
    refute endpoint.valid?
    endpoint.space_perm_id = 'mmmmm'
    assert endpoint.valid?

    endpoint.as_endpoint = nil
    refute endpoint.valid?
    endpoint.as_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.as_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.dss_endpoint = nil
    refute endpoint.valid?
    endpoint.dss_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.dss_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.web_endpoint = nil
    refute endpoint.valid?
    endpoint.web_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.web_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.refresh_period_mins = nil
    refute endpoint.valid?
    endpoint.refresh_period_mins = 0
    refute endpoint.valid?
    endpoint.refresh_period_mins = 10
    refute endpoint.valid?
    endpoint.refresh_period_mins = 60
    assert endpoint.valid?

    endpoint.project = nil
    refute endpoint.valid?
    endpoint.project = FactoryBot.create(:project)
    assert endpoint.valid?

    endpoint.policy = nil
    refute endpoint.valid?
  end

  test 'default refresh period' do
    assert_equal 120, OpenbisEndpoint.new.refresh_period_mins
  end

  test 'validates uniqueness' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    endpoint2 = OpenbisEndpoint.new project: FactoryBot.create(:project),
                                    username: endpoint.username,
                                    password: endpoint.password,
                                    web_endpoint: endpoint.web_endpoint,
                                    as_endpoint: endpoint.as_endpoint,
                                    dss_endpoint: endpoint.dss_endpoint,
                                    space_perm_id: endpoint.space_perm_id,
                                    refresh_period_mins: endpoint.refresh_period_mins

    assert endpoint2.valid? # different project

    endpoint2 = OpenbisEndpoint.new project: endpoint.project,
                                    username: endpoint.username,
                                    password: endpoint.password,
                                    web_endpoint: endpoint.web_endpoint,
                                    as_endpoint: endpoint.as_endpoint,
                                    dss_endpoint: endpoint.dss_endpoint,
                                    space_perm_id: endpoint.space_perm_id,
                                    refresh_period_mins: endpoint.refresh_period_mins

    refute endpoint2.valid?

    endpoint2.as_endpoint = 'http://fish.com'
    assert endpoint2.valid?

    endpoint2.as_endpoint = endpoint.as_endpoint
    refute endpoint2.valid?

    endpoint2.dss_endpoint = 'http://fish.com'
    assert endpoint2.valid?
  end

  test 'default policy' do
    endpoint = OpenbisEndpoint.new
    refute_nil endpoint.policy
  end

  test 'link to project' do
    pa = FactoryBot.create(:project_administrator)
    project = pa.projects.first
    User.with_current_user(pa.user) do
      with_config_value :openbis_enabled, true do
        endpoint = OpenbisEndpoint.create project: project, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', web_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'aaa'
        endpoint2 = OpenbisEndpoint.create project: project, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', web_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'bbb'
        endpoint.save!
        endpoint2.save!
        project.reload
        assert_equal [endpoint, endpoint2].sort, project.openbis_endpoints.sort
      end
    end
  end

  test 'can_create' do
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
      with_config_value :openbis_enabled, true do
        assert OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(FactoryBot.create(:person).user) do
      with_config_value :openbis_enabled, true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled, true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end
  end

  test 'can_delete?' do
    person = FactoryBot.create(:person)
    ep = FactoryBot.create(:openbis_endpoint, project: person.projects.first)
    refute ep.can_delete?(person.user)
    User.with_current_user(person.user) do
      refute ep.can_delete?
    end

    pa = FactoryBot.create(:project_administrator)
    ep = FactoryBot.create(:openbis_endpoint, project: pa.projects.first)
    assert ep.can_delete?(pa.user)
    User.with_current_user(pa.user) do
      assert ep.can_delete?
    end

    another_pa = FactoryBot.create(:project_administrator)
    refute ep.can_delete?(another_pa.user)
    User.with_current_user(another_pa.user) do
      refute ep.can_delete?
    end

    # cannot delete if linked
    # first check another linked endpoint doesn't prevent delete
    df = openbis_linked_data_file(person)
    assert_not_equal df.openbis_dataset.openbis_endpoint, ep

    assert ep.can_delete?(pa.user)
    User.with_current_user(pa.user) do
      assert ep.can_delete?
    end
  end

  test 'available spaces' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    spaces = endpoint.available_spaces
    assert_equal 2, spaces.count
  end

  test 'space' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    space = endpoint.do_authentication.space
    refute_nil space
    assert_equal 'API-SPACE', space.perm_id
  end

  test 'can edit?' do
    pa = FactoryBot.create(:project_administrator).user
    user = FactoryBot.create(:person).user
    endpoint = OpenbisEndpoint.create project: pa.person.projects.first, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'aaa'
    User.with_current_user(pa) do
      with_config_value :openbis_enabled, true do
        assert endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(user) do
      with_config_value :openbis_enabled, true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled, true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    with_config_value :openbis_enabled, true do
      assert endpoint.can_edit?(pa)
      refute endpoint.can_edit?(user)
      refute endpoint.can_edit?(nil)

      # cannot edit if another project admin
      pa2 = FactoryBot.create(:project_administrator).user
      refute endpoint.can_edit?(pa2)
    end
  end

  test 'session token' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    refute_nil endpoint.session_token
  end

  test 'destroy' do
    pa = FactoryBot.create(:project_administrator)
    endpoint = FactoryBot.create(:openbis_endpoint, project: pa.projects.first)
    metadata_store = endpoint.metadata_store
    key = endpoint.do_authentication.space.cache_key(endpoint.space_perm_id)
    assert metadata_store.exist?(key)
    assert_difference('OpenbisEndpoint.count', -1) do
      User.with_current_user(pa.user) do
        endpoint.destroy
      end
    end
    refute metadata_store.exist?(key)
  end

  test 'clear metadata store' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    key = endpoint.do_authentication.space.cache_key(endpoint.space_perm_id)
    assert endpoint.metadata_store.exist?(key)
    endpoint.clear_metadata_store
    refute endpoint.metadata_store.exist?(key)
  end

  test 'clears metadata store on details update' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    key = endpoint.do_authentication.space.cache_key(endpoint.space_perm_id)
    assert endpoint.metadata_store.exist?(key)

    disable_authorization_checks do
      assert endpoint.save
      assert endpoint.metadata_store.exist?(key)

      endpoint.username = endpoint.username + '2'
      assert endpoint.save
      refute endpoint.metadata_store.exist?(key)
    end
  end

  test 'create_refresh_metadata_job' do
    endpoint = nil

    assert_no_enqueued_jobs(only: OpenbisEndpointCacheRefreshJob) do
      endpoint = FactoryBot.create(:openbis_endpoint)
    end

    assert_enqueued_with(job: OpenbisEndpointCacheRefreshJob) do
      endpoint.create_refresh_metadata_job
    end
  end

  test 'create_sync_metadata_job' do
    endpoint = nil

    assert_no_enqueued_jobs(only: OpenbisSyncJob) do
      endpoint = FactoryBot.create(:openbis_endpoint)
    end

    assert_enqueued_with(job: OpenbisSyncJob) do
      endpoint.create_sync_metadata_job
    end
  end

  test 'does not create jobs on creation' do
    assert_no_enqueued_jobs(only: [OpenbisSyncJob, OpenbisEndpointCacheRefreshJob]) do
      FactoryBot.create(:openbis_endpoint)
    end
  end

  test 'jobs do not error for destroyed endpoint' do
    pa = FactoryBot.create(:project_administrator)
    endpoint = FactoryBot.create(:openbis_endpoint, project: pa.projects.first)
    User.with_current_user(pa.user) do
      endpoint.destroy
    end

    assert_nothing_raised do
      OpenbisEndpointCacheRefreshJob.perform_now(endpoint)
      OpenbisSyncJob.perform_now(endpoint)
    end
  end

  test 'encrypted password' do
    endpoint = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: 'frog',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60
    assert_equal 'frog', endpoint.password
    refute_nil endpoint.encrypted_password
    refute_nil endpoint.encrypted_password_iv

    disable_authorization_checks do
      assert endpoint.save
    end

    endpoint = OpenbisEndpoint.find(endpoint.id)
    assert_equal 'frog', endpoint.password
    refute_nil endpoint.encrypted_password
    refute_nil endpoint.encrypted_password_iv
  end

  test 'follows external_assets' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    zample = Seek::Openbis::Zample.new(endpoint, '20171002172111346-37')
    options = { tomek: false }

    asset1 = OpenbisExternalAsset.build(zample, options)

    dataset = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23')
    asset2 = OpenbisExternalAsset.build(dataset, options)

    endpoint2 = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, web_endpoint: 'https://openbis-api.fair-dom.org/openbis2', space_perm_id: 'API-SPACE2')

    zample2 = Seek::Openbis::Zample.new(endpoint2, '20171002172111346-37')
    asset3 = OpenbisExternalAsset.build(zample2, options)

    assert asset1.save
    assert asset2.save
    assert asset3.save!

    endpoint.reload
    endpoint2.reload

    e1ass = endpoint.external_assets.to_ary
    assert_equal 2, e1ass.length
    assert e1ass.include? asset1
    assert e1ass.include? asset2

    # such comparision does not work on postgress different ordering
    # assert_equal [asset1, asset2], endpoint.external_assets.to_ary
    assert_equal [asset3], endpoint2.external_assets.to_ary
  end

  test 'registered_datafiles finds only own datafiles' do
    endpoint1 = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space1',
                                    refresh_period_mins: 60

    endpoint2 = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space2',
                                    refresh_period_mins: 60

    disable_authorization_checks do
      assert endpoint1.save
      assert endpoint2.save
    end

    datafile1 = @seek_util.createDataFileFromObisSet(Seek::Openbis::Dataset.new(endpoint1, '20160210130454955-23'), nil)
    assert datafile1.save
    datafile2 = @seek_util.createDataFileFromObisSet(Seek::Openbis::Dataset.new(endpoint1, '20160215111736723-31'), nil)
    assert datafile2.save
    datafile3 = @seek_util.createDataFileFromObisSet(Seek::Openbis::Dataset.new(endpoint2, '20160210130454955-23'), nil)
    assert datafile3.save

    df = endpoint1.registered_datafiles
    assert_includes df, datafile1
    assert_includes df, datafile2
    assert_not_includes df, datafile3

    df = endpoint2.registered_datafiles
    assert_equal [datafile3], df
  end

  test 'registered_datasets gives only own datafiles' do
    endpoint1 = FactoryBot.create :openbis_endpoint

    endpoint2 = FactoryBot.create :openbis_endpoint

    disable_authorization_checks do
      assert endpoint1.save
      assert endpoint2.save
    end

    set1 = Seek::Openbis::Dataset.new(endpoint1, '20160210130454955-23')
    asset1 = OpenbisExternalAsset.build(set1)
    df1 = FactoryBot.create :data_file
    asset1.seek_entity = df1
    assert asset1.save

    set2 = Seek::Openbis::Dataset.new(endpoint1, '20160215111736723-31')
    asset2 = OpenbisExternalAsset.build(set2)
    df2 = FactoryBot.create :data_file
    asset2.seek_entity = df2
    assert asset2.save

    set3 = Seek::Openbis::Dataset.new(endpoint2, '20160210130454955-23')
    asset3 = OpenbisExternalAsset.build(set3)
    df3 = FactoryBot.create :data_file
    asset3.seek_entity = df3
    assert asset3.save

    registered = endpoint1.registered_datasets
    assert_equal 2, registered.count

    registered.each do |e|
      assert e.is_a? DataFile
    end

    registered = endpoint2.registered_datasets
    assert_equal 1, registered.count
  end

  test 'registered_assays gives own zamples registered in seek as assays' do
    endpoint1 = FactoryBot.create :openbis_endpoint

    zample1 = zample_for_id('12', endpoint1)

    zample2 = zample_for_id('12')

    zample3 = zample_for_id('13', endpoint1)

    asset1 = OpenbisExternalAsset.build(zample1)
    asset1.seek_entity = FactoryBot.create :assay

    asset2 = OpenbisExternalAsset.build(zample2)
    asset2.seek_entity = FactoryBot.create :assay

    asset3 = OpenbisExternalAsset.build(zample3)
    asset3.seek_entity = FactoryBot.create :assay

    assert asset1.save
    assert asset2.save
    assert asset3.save

    assert_equal 3, OpenbisExternalAsset.count

    assert_equal 2, endpoint1.registered_assays.count

    endpoint1.registered_assays.each do |e|
      assert e.is_a? Assay
    end

    assert_equal 1, zample2.openbis_endpoint.registered_assays.count
  end

  test 'registered_studies gives own entries registered in seek as studies' do
    endpoint1 = FactoryBot.create :openbis_endpoint

    endpoint2 = FactoryBot.create :openbis_endpoint

    disable_authorization_checks do
      assert endpoint1.save
      assert endpoint2.save
    end

    e1 = Seek::Openbis::Experiment.new(endpoint1, '20171121152132641-51')
    asset1 = OpenbisExternalAsset.build(e1)
    st1 = FactoryBot.create :study
    asset1.seek_entity = st1
    assert asset1.save

    e2 = Seek::Openbis::Experiment.new(endpoint2, '20171121152132641-51')
    asset2 = OpenbisExternalAsset.build(e2)
    st2 = FactoryBot.create :study
    asset2.seek_entity = st2
    assert asset2.save

    e3 = Seek::Openbis::Experiment.new(endpoint1, '20171121153715264-58')
    asset3 = OpenbisExternalAsset.build(e3)
    st3 = FactoryBot.create :study
    asset3.seek_entity = st3
    assert asset3.save

    assert_equal 3, OpenbisExternalAsset.count

    assert_equal 2, endpoint1.registered_studies.count

    endpoint1.registered_studies.each do |e|
      assert e.is_a? Study
    end

    assert_equal 1, endpoint2.registered_studies.count
  end

  def zample_for_id(permId = nil, endpoint = nil)
    endpoint ||= FactoryBot.create :openbis_endpoint

    json = JSON.parse(
      '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40","20171004182824553-41"]
,"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )
    json['permId'] = permId if permId
    Seek::Openbis::Zample.new(endpoint).populate_from_json(json)
  end

  # test 'reindex_entities queues new indexing job' do
  #  endpoint = FactoryBot.create(:openbis_endpoint)
  #  datafile1 = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23').create_seek_datafile
  #  assert datafile1.save
  #  # don't know how to test that it was really reindexing job with correct content
  # assert_enqueued_with(job: ReindexingJob) do
  #    endpoint.reindex_entities
  #  end
  #  assert ReindexingQueue.exists?(item: datafile1)
  # end

  # it should actually test for synchronization but I don't know how to achieve it
  # needs OpenBIS mock that can be set to return particular values
  test 'refresh_metadata cleanups store, marks for refresh and adds sync job' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    dataset = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)
    asset.synchronized_at = DateTime.now - 1.days
    assert asset.save

    store = endpoint.metadata_store
    key1 = 'stays'
    store.fetch(key1) { 'Tomek' }

    key2 = 'goes'
    store.fetch(key2, expires_in: 0.1.seconds) { 'Marek' }

    assert_equal 'Tomek', store.fetch(key1)
    assert_equal 'Marek', store.fetch(key2)

    old_timestamp = endpoint.last_cache_refresh

    sleep(0.2.seconds)

    endpoint.refresh_metadata
    assert_not_equal old_timestamp, endpoint.last_cache_refresh, 'Should update `last_cache_refresh` timestamp'

    assert endpoint.metadata_store.exist?(key1)
    refute endpoint.metadata_store.exist?(key2)

    asset.reload
    assert asset.refresh?
  end

  test 'force_refresh_metadata clears store, marks all for refresh' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    dataset = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)
    asset.synchronized_at = DateTime.now
    assert asset.save

    store = endpoint.metadata_store
    key1 = 'stays'
    store.fetch(key1) { 'Tomek' }

    key2 = 'goes'
    store.fetch(key2, expires_in: 0.1.seconds) { 'Marek' }

    assert_equal 'Tomek', store.fetch(key1)
    assert_equal 'Marek', store.fetch(key2)

    endpoint.force_refresh_metadata

    refute endpoint.metadata_store.exist?(key1)
    refute endpoint.metadata_store.exist?(key2)

    asset.reload
    assert asset.refresh?
  end

  test 'due_to_refresh gives synchronized assets with elapsed synchronization time' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    endpoint.refresh_period_mins = 80
    disable_authorization_checks do
      assert endpoint.save!
    end

    assets = []
    (0..9).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = endpoint
      asset.external_service = endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :synchronized
      asset.synchronized_at = DateTime.now - i.hours
      assert asset.save
      assets << asset
    end

    assets[9].sync_state = :refresh
    assets[9].save

    assets[8].sync_state = :failed
    assets[8].save

    endpoint.reload
    assert_equal 10, endpoint.external_assets.count

    due = endpoint.due_to_refresh.to_a
    assert_equal 6, due.count
    # that does not work on postgres as different ordering
    # assert_equal assets[2..7].map { |r| r.external_id }, endpoint.due_to_refresh.map { |r| r.external_id }

    assets[2..7].each { |a| assert due.include?(a) }
  end

  test 'mark_for_refresh sets sync status for all due to refresh' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    endpoint.refresh_period_mins = 80
    disable_authorization_checks do
      assert endpoint.save!
    end

    assets = []
    (0..9).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = endpoint
      asset.external_service = endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :synchronized
      asset.synchronized_at = DateTime.now - i.hours
      assert asset.save
      assets << asset
    end

    assets[9].sync_state = :failed
    assets[9].save

    endpoint.reload
    assert_equal 10, endpoint.external_assets.count

    endpoint.mark_for_refresh

    assets.each &:reload

    assert assets[9].failed?
    assert assets[0].synchronized?
    assert assets[1].synchronized?
    assets[2..8].each { |a| assert a.refresh? }
  end

  test 'mark_all_for_refresh sets sync status for all synchronized to refresh' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    endpoint.refresh_period_mins = 80
    disable_authorization_checks do
      assert endpoint.save!
    end

    assets = []
    (0..9).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = endpoint
      asset.external_service = endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :synchronized
      asset.synchronized_at = DateTime.now - i.hours
      assert asset.save
      assets << asset
    end

    assets[9].sync_state = :failed
    assets[9].save

    endpoint.reload
    assert_equal 10, endpoint.external_assets.count

    endpoint.mark_all_for_refresh

    assets.each &:reload

    assert assets[9].failed?
    assets[0..8].each { |a| assert a.refresh? }
  end

  test 'build_meta_config makes valid hash even on nil parameters' do
    conf = OpenbisEndpoint.build_meta_config(nil, nil)
    exp = { study_types: [], assay_types: [] }
    assert_equal exp, conf

    conf = OpenbisEndpoint.build_meta_config(%w[st1 st2], ['a1'])
    exp = { study_types: %w[st1 st2], assay_types: ['a1'] }
    assert_equal exp, conf
  end

  test 'build_meta_config raise exception if not empty non-table parameters' do
    assert_raise do
      OpenbisEndpoint.build_meta_config('a', nil)
    end
    assert_raise do
      OpenbisEndpoint.build_meta_config(nil, 'b')
    end
  end

  test 'default_meta_config contains standard OpenBIS ELN types' do
    conf = OpenbisEndpoint.default_meta_config
    exp = { study_types: ['DEFAULT_EXPERIMENT'], assay_types: ['EXPERIMENTAL_STEP'] }
    assert_equal exp, conf
  end

  test 'add_meta_config sets default config for new entry' do
    project = FactoryBot.create(:project)
    endpoint = OpenbisEndpoint.new project: project, username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60

    refute endpoint.study_types.empty?
    refute endpoint.assay_types.empty?
    refute endpoint.meta_config_json

    disable_authorization_checks do
      endpoint.save!
    end

    assert endpoint.meta_config_json

    # passing the content for init
    endpoint = OpenbisEndpoint.new project: project, username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis1',
                                   as_endpoint: 'http://my-openbis.org/openbis1',
                                   dss_endpoint: 'http://my-openbis.org/openbis1',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60,
                                   meta_config_json: '{}'

    assert endpoint.meta_config_json
    assert endpoint.study_types.empty?
    assert endpoint.assay_types.empty?
  end

  test 'meta_config is serialized to json before saving' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    endpoint.study_types = ['ST1']
    endpoint.assay_types = []

    exp = { study_types: ['ST1'], assay_types: [] }.to_json
    assert_not_equal exp, endpoint.meta_config_json

    disable_authorization_checks do
      endpoint.save!
    end

    assert_equal exp, endpoint.meta_config_json

    endpoint = OpenbisEndpoint.find(endpoint.id)
    assert_equal ['ST1'], endpoint.study_types
    assert_equal [], endpoint.assay_types
  end

  test 'study_types gives default for new record configured' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    assert_equal ['DEFAULT_EXPERIMENT'], endpoint.study_types
  end

  test 'study_types can be set as string' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    exp = %w[S1 S2]
    endpoint.study_types = ' S1 S2'

    assert_equal exp, endpoint.study_types

    disable_authorization_checks do
      endpoint.save!
    end
    endpoint1 = OpenbisEndpoint.find(endpoint.id)
    assert_not_same endpoint, endpoint1
    assert_equal exp, endpoint1.study_types
  end

  test 'study_types can be set as array' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    exp = %w[S1 S2]
    endpoint.study_types = exp

    assert_equal exp, endpoint.study_types

    disable_authorization_checks do
      endpoint.save!
    end
    endpoint1 = OpenbisEndpoint.find(endpoint.id)
    assert_not_same endpoint, endpoint1
    assert_equal exp, endpoint1.study_types
  end

  test 'study_types are read from meta_config' do
    endpoint = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis1',
                                   as_endpoint: 'http://my-openbis.org/openbis1',
                                   dss_endpoint: 'http://my-openbis.org/openbis1',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60,
                                   meta_config_json: { study_types: ['S'], assay_types: [] }.to_json

    assert_equal ['S'], endpoint.study_types
  end

  test 'assay_types gives default if not configured' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    assert_equal ['EXPERIMENTAL_STEP'], endpoint.assay_types
  end

  test 'assay_types can be set as string' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    exp = %w[A1 A2]
    endpoint.assay_types = ' A1, A2'

    assert_equal exp, endpoint.assay_types

    disable_authorization_checks do
      endpoint.save!
    end
    endpoint1 = OpenbisEndpoint.find(endpoint.id)
    assert_not_same endpoint, endpoint1
    assert_equal exp, endpoint1.assay_types
  end

  test 'assay_types can be set as array' do
    endpoint = FactoryBot.create(:openbis_endpoint)
    exp = %w[A1 A2]
    endpoint.assay_types = exp

    assert_equal exp, endpoint.assay_types

    disable_authorization_checks do
      endpoint.save!
    end
    endpoint1 = OpenbisEndpoint.find(endpoint.id)
    assert_not_same endpoint, endpoint1
    assert_equal exp, endpoint1.assay_types
  end

  test 'assay_types are read from meta_config' do
    endpoint = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis1',
                                   as_endpoint: 'http://my-openbis.org/openbis1',
                                   dss_endpoint: 'http://my-openbis.org/openbis1',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60,
                                   meta_config_json: { study_types: ['S'], assay_types: ['A'] }.to_json

    assert_equal ['A'], endpoint.assay_types
  end

  test 'parses string with code names using , and white spaces as separators' do
    endpoint = FactoryBot.create(:openbis_endpoint)

    input = nil
    names = endpoint.parse_code_names(input)
    assert_equal [], names

    input = ''
    names = endpoint.parse_code_names(input)
    assert_equal [], names

    input = ' '
    names = endpoint.parse_code_names(input)
    assert_equal [], names

    input = ' N1, N2
, name
  name2, again N1
'
    names = endpoint.parse_code_names(input)
    assert_equal %w[N1 N2 NAME NAME2 AGAIN], names
  end

  test 'due for sync?' do
    assert FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60).due_sync?
    assert FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_sync: 2.years.ago).due_sync?
    refute FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_sync: 2.seconds.ago).due_sync?
  end

  test 'due for cache refresh?' do
    assert FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60).due_cache_refresh?
    assert FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_cache_refresh: 2.hours.ago).due_cache_refresh?
    refute FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_cache_refresh: 30.minutes.ago).due_cache_refresh?
  end
end
