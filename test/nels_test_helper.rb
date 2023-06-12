module NelsTestHelper

  def setup_nels_for_units
    create_sample_attribute_type

    @project = FactoryBot.create(:project)
    @project.settings.set('nels_enabled', true)
    person = FactoryBot.create(:person, project: @project)
    @user = person.user
    @nels_access_token = 'fake-access-token'

    @user.oauth_sessions.where(provider: 'NeLS').create(access_token: @nels_access_token, expires_at: 1.week.from_now)

    @assay = FactoryBot.create(:assay, contributor: person)

    @project_id = 91123122
    @dataset_id = 91123528
    @subtype = 'reads'
    @reference = 'xMTEyMzEyMjoxMTIzNTI4OnJlYWRz'

    disable_authorization_checks do
      @nels_sample_type = SampleType.new(title: 'NeLS FASTQ Paired', uploaded_template: true, project_ids: [@project.id], contributor: @user.person)
      @nels_sample_type.content_blob = FactoryBot.create(:nels_fastq_paired_template_content_blob)
      @nels_sample_type.build_attributes_from_template
      @nels_sample_type.save!
    end
  end

  def setup_nels
    setup_nels_for_units

    login_as(@user)
  end

end
