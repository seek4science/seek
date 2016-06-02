xss_inst = Institution.where(title: "<script>alert('xss in institution title');</script> Institution £&%>",
                             country: 'United Kingdom').first_or_create!
xss_project = Project.where(title: "<script>alert('xss in project title');</script> Project £&%>").first_or_create!
xss_person = Person.where(first_name: 'John', last_name: "<script>alert('xss in person lastname');</script> Smith&", email: 'jxsss@example.com').first_or_create!

xss_i = Investigation.where(title: "<script>alert('xss in investigation');</script> Investigation £&%>").
    first_or_create!(projects: [xss_project], policy: Policy.public_policy)
xss_s = Study.where(title: "<script>alert('xss in study');</script> Study £&%>").
    first_or_create!(investigation: xss_i, policy: Policy.public_policy)
xss_a = Assay.where(title: "<script>alert('xss in assay');</script> Assay £&%>").
    first_or_create!(study: xss_s, policy: Policy.public_policy, owner: xss_person, assay_class: AssayClass.first)

puts 'Seeded XSS dummy data'
