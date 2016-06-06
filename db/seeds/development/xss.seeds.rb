class << self
  def new_content_blob(asset)
    ContentBlob.new(asset: asset, asset_version: 1, content_type: 'text/plain', data: '123', original_filename: 'file.txt')
  end
end

disable_authorization_checks do
  xss_inst = Institution.where(title: "<script>alert('xss in institution title');</script> Institution £&%>",
                               country: 'United Kingdom').first_or_create!
  xss_project = Project.where(title: "<script>alert('xss in project title');</script> Project £&%>").first_or_create!
  xss_person = Person.where(first_name: 'John', last_name: "<script>alert('xss in person lastname');</script> Smith&",
                            email: 'jxsss@example.com').first_or_create!

  xss_i = Investigation.where(title: "<script>alert('xss in investigation');</script> Investigation £&%>").
      first_or_create!(projects: [xss_project], policy: Policy.public_policy)
  xss_s = Study.where(title: "<script>alert('xss in study');</script> Study £&%>").
      first_or_create!(investigation: xss_i, policy: Policy.public_policy)
  xss_a = Assay.where(title: "<script>alert('xss in assay');</script> Assay £&%>").
      first_or_create!(study: xss_s, policy: Policy.public_policy, owner: xss_person, assay_class: AssayClass.first)

  xss_d = DataFile.where(title: "<script>alert('xss in datafile');</script> DataFile £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project]) do |df|
    df.content_blob = new_content_blob(df)
  end
  xss_a.associate(xss_d)

  xss_m = Model.where(title: "<script>alert('xss in model');</script> Model £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project]) do |m|
    m.content_blobs = [new_content_blob(m)]
  end

  xss_s = Sop.where(title: "<script>alert('xss in sop');</script> SOP £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project]) do |s|
    s.content_blob = new_content_blob(s)
  end

  xss_pr = Presentation.where(title: "<script>alert('xss in presentation');</script> Presentation £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project]) do |p|
    p.content_blob = new_content_blob(p)
  end

  xss_pub = Publication.where(title: "<script>alert('xss in publication');</script> Publication £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project], pubmed_id: 1611890)

  xss_e = Event.where(title: "<script>alert('xss in event');</script> Event £&%>").first_or_create!(
      policy: Policy.public_policy, contributor: xss_person, projects: [xss_project],
      start_date: 10.days.ago, end_date: 10.days.from_now)

  xss_st = SampleType.where(title: "<script>alert('xss in sample type');</script> Sample Type £&%>").first_or_create!(
      sample_attributes_attributes: {
          '0' => {
              pos: '1', title: "<script>alert('xss in sample type attribute name');</script> Attribute Name £&%>",
              required: '1', is_title: '1', sample_attribute_type_id: SampleAttributeType.find_by_title('Text').id,
              _destroy: '0' },
      }
  )

  xss_sample_title = "<script>alert('xss in sample');</script> Sample £&%>"
  xss_samp = Sample.where(title: xss_sample_title).first_or_create!(
                                                      policy: Policy.public_policy,
                                                      sample_type_id: xss_st.id,
                                                      data: { script_alert_xss_in_sample_type_attribute_name_script_attribute_name: xss_sample_title }
  )

end

puts 'Seeded XSS dummy data'
