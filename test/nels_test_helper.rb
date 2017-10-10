module NelsTestHelper

  def setup_nels_for_units
    person = Factory(:person)
    @user = person.user
    @project = person.projects.first
    @project.settings['nels_enabled'] = true
    @nels_access_token = 'fake-access-token'

    @user.oauth_sessions.where(provider: 'NeLS').create(access_token: @nels_access_token, expires_at: 1.week.from_now)

    study = Factory(:study, investigation: Factory(:investigation, project_ids: [@project.id]))
    @assay = Factory(:assay, contributor: person, study: study)

    @project_id = 91123122
    @dataset_id = 91123528
    @subtype = 'reads'
    @reference = 'xMTEyMzEyMjoxMTIzNTI4OnJlYWRz'
  end

  def setup_nels
    setup_nels_for_units

    login_as(@user)
  end

end