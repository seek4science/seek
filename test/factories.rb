#A couple of these rely on certain things existing in the test db ahead of time.
#:pal relies on Role.pal_role being able to find an appropriate role in the db.
#:assay_modelling and :assay_experimental rely on the existence of the AssayClass's

#Person
  Factory.define(:brand_new_person, :class => Person) do |f|
    f.sequence(:email) { |n| "test#{n}@test.com" }
    f.sequence(:first_name) { |n| "Person#{n}" }
    f.last_name "Last"
  end

  Factory.define(:person_in_project, :parent => :brand_new_person) do |f|
    f.group_memberships {[Factory.build :group_membership]}
  end

  Factory.define(:person, :parent => :person_in_project) do |f|
    f.association :user, :factory => :activated_user
  end

  Factory.define(:admin,:parent=>:person) do |f|
    f.is_admin true
  end

  Factory.define(:pal, :parent => :person) do |f|
    f.is_pal true
    f.after_create { |pal| pal.group_memberships.first.roles << Role.pal_role}
  end

#User
  Factory.define(:brand_new_user, :class => User) do |f|
    f.sequence(:login) { |n| "user#{n}" }
    test_password = "blah"
    f.password test_password
    f.password_confirmation test_password
  end

  #activated_user mainly exists for :person to use in its association
  Factory.define(:activated_user, :parent => :brand_new_user) do |f|
    f.after_create { |user| user.activate }
  end

  Factory.define(:user_not_in_project,:parent => :activated_user) do |f|
    f.association :person, :factory => :brand_new_person
  end

  Factory.define(:user, :parent => :activated_user) do |f|
    f.association :person, :factory => :person_in_project
  end

#Project
  Factory.define(:project) do |f|
    f.sequence(:title) { |n| "A Project: #{n}" }
  end

#Institution
  Factory.define(:institution) do |f|
    f.sequence(:title) { |n| "An Institution: #{n}" }
  end

#Sop
  Factory.define(:sop) do |f|
    f.title "This Sop"
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :user
  end

#Policy
  Factory.define(:policy, :class => Policy) do |f|
    f.name "test policy"
  end

  Factory.define(:private_policy, :parent => :policy) do |f|
    f.sharing_scope Policy::PRIVATE
    f.access_type Policy::NO_ACCESS
  end

  Factory.define(:public_policy, :parent => :policy) do |f|
    f.sharing_scope Policy::EVERYONE
    f.access_type Policy::MANAGING
  end

  Factory.define(:all_sysmo_viewable_policy,:parent=>:policy) do |f|
    f.sharing_scope Policy::ALL_SYSMO_USERS
    f.access_type Policy::VISIBLE
  end

#Permission
  Factory.define(:permission, :class => Permission) do |f|
    f.association :contributor, :factory => :person
    f.association :policy
    f.access_type Policy::NO_ACCESS
  end

#Assay and Technology types

  Factory.define(:technology_type, :class=>TechnologyType) do |f|
    f.sequence(:title) {|n| "A TechnologyType#{n}"}
  end

  Factory.define(:assay_type) do |f|
    f.sequence(:title) {|n| "An AssayType#{n}"}
  end

#Assay
Factory.define(:assay_base, :class => Assay) do |f|
  f.title "An Assay"
    f.association :contributor, :factory => :person
  f.association :study
  f.association :assay_type

end

Factory.define(:modelling_assay_class, :class => AssayClass) do |f|
  f.title 'Modelling Assay'
  f.key 'MODEL'
end

Factory.define(:experimental_assay_class, :class => AssayClass) do |f|
  f.title 'Experimental Assay'
  f.key 'EXP'
end

Factory.define(:modelling_assay, :parent => :assay_base) do |f|
  f.association :assay_class, :factory => :modelling_assay_class
  f.samples {[Factory.build :sample]}

end

Factory.define(:modelling_assay_with_organism, :parent => :modelling_assay) do |f|
  f.after_create{|ma|Factory.build(:organism,:assay=>ma)}

end
Factory.define(:experimental_assay, :parent => :assay_base) do |f|
  f.association :assay_class, :factory => :experimental_assay_class
  f.association :technology_type
  f.samples {[Factory.build :sample]}
end

  Factory.define(:assay, :parent => :modelling_assay) {}

#Study
Factory.define(:study) do |f|
  f.sequence(:title) { |n| "Study#{n}" }
  f.association :investigation
  f.association :contributor, :factory => :person
end

#Investigation
Factory.define(:investigation) do |f|
  f.projects {[Factory.build(:project)]}
  f.sequence(:title) { |n| "Investigation#{n}" }
end

#Strain
Factory.define(:strain) do |f|
  f.sequence(:title) { |n| "Strain#{n}" }
end

#Culture growth type
Factory.define(:culture_growth_type) do |f|
  f.title "a culture_growth_type"
end

#Tissue and cell type
Factory.define(:tissue_and_cell_type) do |f|
  f.title "a tissue and cell type"
end


#Specimen
Factory.define(:specimen) do |f|
  f.sequence(:donor_number) { |n| "Specimen#{n}" }
  f.sequence(:lab_internal_number) { |n| "Lab#{n}" }
  f.association :contributor, :factory => :user
  f.projects {[Factory.build(:project)]}
  f.association :institution
  f.association :organism
end

#Sample
Factory.define(:sample) do |f|
  f.sequence(:title) { |n| "Sample#{n}" }
  f.sequence(:lab_internal_number) { |n| "Lab#{n}" }
  f.donation_date Date.today
  f.association :specimen
end


#Data File
  Factory.define(:data_file) do |f|
    f.sequence(:title) {|n| "A Data File_#{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :user
    f.association :content_blob, :factory => :content_blob
  end

#Model
  Factory.define(:model) do |f|
    f.title "A Model"
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :user
  end

#Publication
  Factory.define(:publication) do |f|
    f.title "A Model"
    f.pubmed_id 1
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :user
  end
#Presentation
Factory.define(:presentation) do |f|
  f.title "A Presentation"
  f.projects {[Factory.build :project]}
 # f.data_url "http://www.virtual-liver.de/images/logo.png"
  f.association :contributor,:factory=>:user
  f.association :content_blob, :factory => :content_blob
end

#Misc
  Factory.define(:group_membership) do |f|
    f.association :work_group
  end

  Factory.define(:role) do |f|
    f.name "A Role"
  end

  Factory.define(:work_group) do |f|
    f.association :project
    f.association :institution
  end

  Factory.define(:organism) do |f|
    f.title "An Organism"
  end

  Factory.define(:event) do |f|
    f.title "An Event"
    f.start_date Time.now
    f.end_date 1.days.from_now
  end

#Content_blob
#either url or data should be provided for assets
  Factory.define(:content_blob) do |f|
    f.uuid UUIDTools::UUID.random_create.to_s
    f.sequence(:data) {|n| "data [#{n}]" }
  end

  Factory.define(:activity_log) do |f|
    f.action "create"
    f.association :activity_loggable, :factory => :data_file
    f.association :culprit, :factory => :user
  end

  #Factor studied
  Factory.define(:studied_factor) do |f|
    f.start_value 1
    f.end_value 10
    f.standard_deviation 2
    f.data_file_version 1
    f.association :measured_item, :factory => :measured_item
    f.association :unit, :factory => :unit
    f.association :substance, :factory => :compound
    f.association :data_file, :factory => :data_file
  end

  Factory.define(:project_subscription) do |f|
    f.association :person
    f.association :project
  end

  Factory.define(:subscription) do |f|
    f.association :person
    f.association :subscribable
  end

  Factory.define(:subscribable, :parent => :data_file){}

  Factory.define(:notifiee_info) do |f|
    f.association :notifiee, :factory => :person
  end
    
  Factory.define(:measured_item) do |f|
    f.title 'concentration'
  end

  Factory.define(:unit) do |f|
    f.symbol 'g'
    f.sequence(:order) {|n| n}
  end

  Factory.define(:compound) do |f|
    f.sequence(:name) {|n| "glucose #{n}"}
  end

 #Experimental condition
  Factory.define(:experimental_condition) do |f|
    f.start_value 1
    f.end_value 10
    f.sop_version 1
    f.association :measured_item, :factory => :measured_item
    f.association :unit, :factory => :unit
    f.association :substance, :factory => :compound
    f.association :sop, :factory => :sop
  end

Factory.define(:scalable,:parent=>:data_file){}

#Scale
Factory.define(:scale) do |f|
  f.sequence(:title){|n| "Scale #{n}"}

end
#Scaling
Factory.define(:scaling) do |f|
  f.association :person
  f.association :scalable
  f.association :scale
end

