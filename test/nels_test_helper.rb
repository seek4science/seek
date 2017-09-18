module NelsTestHelper

  def setup_nels
    person = Factory(:person)
    @user = person.user
    @project = person.projects.first
    @project.settings['nels_enabled'] = true

    @user.oauth_sessions.where(provider: 'NeLS').create(access_token: 'fake-access-token', expires_at: 1.week.from_now)

    login_as(@user)

    study = Factory(:study, investigation: Factory(:investigation, project_ids: [@project.id]))
    @assay = Factory(:assay, contributor: person, study: study)

    @project_id = 91123122
    @dataset_id = 91123528
    @subtype = 'reads'
    @reference = 'xMTEyMzEyMjoxMTIzNTI4OnJlYWRz'
  end

end