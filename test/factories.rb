#A couple of these rely on certain things existing in the test db ahead of time.
#:pal relies on Role.pal_role being able to find an appropriate role in the db.
#:assay_modelling and :assay_experimental rely on the existence of the AssayClass's
include ActionDispatch::TestProcess
#Person
  Factory.define(:admin_defined_role_project, :class=>AdminDefinedRoleProject) do |f|

  end

  Factory.define(:admin_defined_role_programme, :class=>AdminDefinedRoleProgramme) do |f|

  end

  Factory.define(:brand_new_person, :class => Person) do |f|
    f.sequence(:email) { |n| "test#{n}@test.com" }
    f.sequence(:first_name) { |n| "Person#{n}" }
    f.last_name "Last"
  end

  Factory.define(:person_in_project, :parent => :brand_new_person) do |f|
    f.group_memberships {[Factory.build(:group_membership)]}
    f.after_create do |p|
      p.reload
    end
  end

  Factory.define(:person_not_in_project, :parent=>:brand_new_person) do |f|
    f.association :user, :factory => :activated_user
  end

  Factory.define(:person_in_multiple_projects, :parent=>:brand_new_person) do |f|
    f.association :user, :factory => :activated_user
    f.group_memberships {[Factory.build(:group_membership),Factory.build(:group_membership),Factory.build(:group_membership)]}
    f.after_create do |p|
      p.reload
    end
  end

  Factory.define(:person, :parent => :person_in_project) do |f|
    f.association :user, :factory => :activated_user
  end

  Factory.define(:admin,:parent=>:person) do |f|
    f.is_admin true
  end

  Factory.define(:pal, :parent => :person) do |f|
    f.roles_mask 2
    f.after_build do |pal|
      Factory(:pal_position) if ProjectPosition.pal_position.nil?
      pal.group_memberships.first.project_positions << ProjectPosition.pal_position
      Factory(:admin_defined_role_project,:project=>pal.projects.first,:person=>pal,:role_mask=>2)
      pal.roles_mask = 2
    end
  end

  Factory.define(:asset_housekeeper,:parent=>:person) do |f|
    f.after_build do |am|
      Factory(:admin_defined_role_project,:project=>am.projects.first,:person=>am,:role_mask=>8)
      am.roles_mask = 8
    end
  end

  Factory.define(:project_administrator,:parent=>:person) do |f|
    f.after_build do |pm|
      Factory(:admin_defined_role_project,:project=>pm.projects.first,:person=>pm,:role_mask=>4)
      pm.roles_mask = 4
    end
  end

  Factory.define(:programme_administrator_not_in_project, :parent=>:person_not_in_project) do |f|
    f.after_build do |pm|
      programme=Factory(:programme)
      Factory(:admin_defined_role_programme,:programme=>programme,:person=>pm,:role_mask=>32)
      pm.roles_mask = 32
    end
  end

  Factory.define(:programme_administrator,:parent=>:project_administrator) do |f|
    f.after_build do |pm|
      programme=Factory(:programme,:projects=>[pm.projects.first])
      Factory(:admin_defined_role_programme,:programme=>programme,:person=>pm,:role_mask=>32)
      pm.roles_mask = 32
    end
  end


  Factory.define(:asset_gatekeeper,:parent=>:person) do |f|
    f.after_build do |gk|
      Factory(:admin_defined_role_project,:project=>gk.projects.first,:person=>gk,:role_mask=>16)
      gk.roles_mask = 16
    end
  end

#User
  Factory.define(:brand_new_user, :class => User) do |f|
    f.sequence(:login) { |n| "user#{n}" }
    test_password = "blah"
    f.password test_password
    f.password_confirmation test_password
  end

  Factory.define(:avatar) do |f|
    f.original_filename "#{Rails.root}/test/fixtures/files/file_picture.png"
    f.image_file File.new("#{Rails.root}/test/fixtures/files/file_picture.png","rb")
    f.association :owner,:factory=>:person
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

#Programme
  Factory.define(:programme) do |f|
    f.sequence(:title) { |n| "A Programme: #{n}"}
    f.projects {[Factory.build(:project)]}
    f.after_create do |p|
      p.is_activated=true
      p.save
    end
  end

#Project
  Factory.define(:project) do |f|
    f.sequence(:title) { |n| "A Project: -#{n}" }
  end

#Institution
  Factory.define(:institution) do |f|
    f.sequence(:title) { |n| "An Institution: #{n}" }
    f.country { ActionView::Helpers::FormOptionsHelper::COUNTRIES.sample }
  end

#Sop
  Factory.define(:sop) do |f|
    f.title "This Sop"
    f.projects { [Factory.build(:project)] }
    f.association :contributor, :factory => :person

    f.after_create do |sop|
      if sop.content_blob.blank?
        sop.content_blob = Factory.create(:content_blob, :content_type => "application/pdf", :asset => sop, :asset_version => sop.version)
      else
        sop.content_blob.asset = sop
        sop.content_blob.asset_version = sop.version
        sop.content_blob.save
      end
    end
  end

  Factory.define(:doc_sop, :parent => :sop) do |f|
    f.association :content_blob, :factory => :doc_content_blob
  end

  Factory.define(:odt_sop, :parent => :sop) do |f|
    f.association :content_blob, :factory => :odt_content_blob
end

  Factory.define(:pdf_sop,:parent=>:sop) do |f|
    f.association :content_blob,:factory=>:pdf_content_blob
  end

  #A SOP that has been registered as a URI
  Factory.define(:url_sop,:parent=>:sop) do |f|
    f.association :content_blob,:factory=>:url_content_blob
  end


  #Policy
  Factory.define(:policy, :class => Policy) do |f|
    f.name "test policy"
    f.sharing_scope Policy::PRIVATE
    f.access_type Policy::NO_ACCESS
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
    f.sharing_scope Policy::ALL_USERS
    f.access_type Policy::VISIBLE
  end

  Factory.define(:all_sysmo_downloadable_policy,:parent=>:policy) do |f|
    f.sharing_scope Policy::ALL_USERS
    f.access_type Policy::ACCESSIBLE
  end

  Factory.define(:publicly_viewable_policy, :parent=>:policy) do |f|
    f.sharing_scope Policy::EVERYONE
    f.access_type Policy::VISIBLE
  end

  Factory.define(:public_download_and_no_custom_sharing,:parent=>:policy) do |f|
    f.sharing_scope Policy::ALL_USERS
    f.access_type Policy::ACCESSIBLE
  end

  Factory.define(:editing_public_policy,:parent=>:policy) do |f|
    f.sharing_scope Policy::EVERYONE
    f.access_type Policy::EDITING
  end

  Factory.define(:downloadable_public_policy,:parent=>:policy) do |f|
    f.sharing_scope Policy::EVERYONE
    f.access_type Policy::ACCESSIBLE
  end

  #Permission
  Factory.define(:permission, :class => Permission) do |f|
    f.association :contributor, :factory => :person
    f.association :policy
    f.access_type Policy::NO_ACCESS
  end

#Suggested Assay and Technology types

  Factory.define(:suggested_technology_type) do |f|
    f.sequence(:label) {|n| "A TechnologyType#{n}"}
    f.ontology_uri "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
  end

  Factory.define(:suggested_assay_type) do |f|
    f.sequence(:label) {|n| "An AssayType#{n}"}
    f.ontology_uri "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
    f.after_build{|type| type.term_type = "assay"}
  end

   Factory.define(:suggested_modelling_analysis_type, :class=> SuggestedAssayType) do |f|
    f.sequence(:label) {|n| "An Modelling Analysis Type#{n}"}
    f.ontology_uri "http://www.mygrid.org.uk/ontology/JERMOntology#Model_analysis_type"
    f.after_build{|type| type.term_type = "modelling_analysis"}
  end

  #Assay
  Factory.define(:assay_base, :class => Assay) do |f|
    f.sequence(:title) {|n| "An Assay #{n}"}
    f.sequence(:description) {|n| "Assay description #{n}"}
    f.association :contributor, :factory => :person
    f.association :study

  end

  Factory.define(:modelling_assay_class, :class => AssayClass) do |f|
    f.title I18n.t('assays.modelling_analysis')
    f.key 'MODEL'
  end

  Factory.define(:experimental_assay_class, :class => AssayClass) do |f|
    f.title I18n.t('assays.experimental_assay')
    f.key 'EXP'
  end

  Factory.define(:modelling_assay, :parent => :assay_base) do |f|
    f.association :assay_class, :factory => :modelling_assay_class
  end

  Factory.define(:modelling_assay_with_organism, :parent => :modelling_assay) do |f|
    f.after_create{|ma|Factory.build(:organism,:assay=>ma)}

  end
  Factory.define(:experimental_assay, :parent => :assay_base) do |f|
    f.association :assay_class, :factory => :experimental_assay_class
    f.assay_type_uri "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
    f.technology_type_uri "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
  end

  Factory.define(:assay, :parent => :modelling_assay) {}

  Factory.define :assay_asset do |f|
    f.association :assay
    f.association :asset,:factory=>:data_file
  end

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
    f.association :contributor, :factory => :person
  end

  #Strain
  Factory.define(:strain) do |f|
    f.sequence(:title) { |n| "Strain#{n}" }
    f.association :organism
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
  end

  #Culture growth type
  Factory.define(:culture_growth_type) do |f|
    f.title "a culture_growth_type"
  end

  #Tissue and cell type
  Factory.define(:tissue_and_cell_type) do |f|
    f.sequence(:title){|n| "Tisse and cell type #{n}"}
  end

  #Assay organism
  Factory.define(:assay_organism) do |f|
    f.association :assay
    f.association :strain
    f.association :organism
  end

  #Data File
  Factory.define(:data_file) do |f|
    f.sequence(:title) {|n| "A Data File_#{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
    f.after_create do |data_file|
      if data_file.content_blob.blank?
        data_file.content_blob = Factory.create(:pdf_content_blob, :asset => data_file, :asset_version=>data_file.version)
      else
        data_file.content_blob.asset = data_file
        data_file.content_blob.asset_version = data_file.version
        data_file.content_blob.save
      end
    end
  end

  Factory.define(:rightfield_datafile,:parent=>:data_file) do |f|
    f.association :content_blob,:factory=>:rightfield_content_blob
  end

  Factory.define(:rightfield_annotated_datafile,:parent=>:data_file) do |f|
    f.association :content_blob,:factory=>:rightfield_annotated_content_blob
  end

  Factory.define(:non_spreadsheet_datafile,:parent=>:data_file) do |f|
    f.association :content_blob,:factory=>:cronwright_model_content_blob
  end

  Factory.define(:xlsx_spreadsheet_datafile,:parent=>:data_file) do |f|
    f.association :content_blob,:factory=>:xlsx_content_blob
  end

  Factory.define(:small_test_spreadsheet_datafile,:parent=>:data_file) do |f|
    f.association :content_blob, :factory=>:small_test_spreadsheet_content_blob
  end

  #Model
  Factory.define(:model) do |f|
    f.sequence(:title) {|n| "A Model #{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
    f.after_create do |model|
       model.content_blobs = [Factory.create(:cronwright_model_content_blob, :asset => model,:asset_version=>model.version)] if model.content_blobs.blank?
    end
  end

  Factory.define(:model_2_files,:class=>Model) do |f|
    f.sequence(:title) {|n| "A Model #{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
    f.after_create do |model|
      model.content_blobs = [Factory.create(:cronwright_model_content_blob, :asset => model,:asset_version=>model.version),Factory.create(:rightfield_content_blob, :asset => model,:asset_version=>model.version)] if model.content_blobs.blank?
    end
  end

  Factory.define(:model_2_remote_files,:class=>Model) do |f|
    f.sequence(:title) {|n| "A Model #{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
    f.after_create do |model|
      model.content_blobs = [Factory.create(:url_content_blob,
                                            :asset => model,
                                            :asset_version => model.version),
                             Factory.create(:url_content_blob,
                                            :asset => model,
                                            :asset_version => model.version)] if model.content_blobs.blank?
    end
  end

  Factory.define(:model_with_image,:parent=>:model) do |f|
    f.sequence(:title) {|n| "A Model with image #{n}"}
    f.after_create do |model|
      model.model_image = Factory(:model_image,:model=>model)
    end
  end

  Factory.define(:model_image) do |f|
    f.original_filename "file_picture.png"
    f.image_file fixture_file_upload("#{Rails.root}/test/fixtures/files/file_picture.png","image/png")
    f.content_type "image/png"
  end

  Factory.define(:cronwright_model,:parent=>:model) do |f|
    f.content_type "text/xml"
    f.association :content_blob,:factory=>:cronwright_model_content_blob
    f.original_filename "cronwright.xml"
  end

  Factory.define(:teusink_model,:parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:teusink_model_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:xgmml_model,:parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:xgmml_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:teusink_jws_model,:parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:teusink_jws_model_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:non_sbml_xml_model,:parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:non_sbml_xml_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:invalid_sbml_model,:parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:invalid_sbml_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:typeless_model, :parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:typeless_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:doc_model, :parent=>:model) do |f|
    f.after_create do |model|
      model.content_blobs = [Factory.create(:doc_content_blob, :asset=>model,:asset_version=>model.version)]
    end
  end

  Factory.define(:model_format) do |f|
    f.sequence(:title) {|n| "format #{n}"}
  end

  #Publication
  Factory.define(:publication) do |f|
    f.sequence(:title) {|n| "A Publication #{n}"}
    f.sequence(:pubmed_id) {|n| n}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
  end

  #Presentation
  Factory.define(:presentation) do |f|
    f.sequence(:title) { |n| "A Presentation #{n}" }
    f.projects { [Factory.build(:project)] }
    f.association :contributor, :factory => :person
    f.after_create do |presentation|
      if presentation.content_blob.blank?
        presentation.content_blob = Factory.create(:content_blob, :original_filename => "test.pdf", :content_type => "application/pdf", :asset => presentation, :asset_version => presentation.version)
      else
        presentation.content_blob.asset = presentation
        presentation.content_blob.asset_version = presentation.version
        presentation.content_blob.save
      end
    end
  end

  Factory.define(:ppt_presentation, :parent => :presentation) do |f|
    f.association :content_blob, :factory => :ppt_content_blob
  end

  Factory.define(:odp_presentation, :parent => :presentation) do |f|
    f.association :content_blob, :factory => :odp_content_blob
  end

  #Model Version
  Factory.define(:model_version,:class=>Model::Version) do |f|
    f.association :model
    f.after_create do |model_version|
      model_version.model.version +=1
      model_version.model.save
      model_version.version = model_version.model.version
      model_version.title = model_version.model.title
      model_version.save
    end
  end

  Factory.define(:model_version_with_blob, :parent => :model_version) do |f|
    f.after_create do |model_version|
      if model_version.content_blobs.empty?
        Factory.create(:teusink_model_content_blob,
                       :asset => model_version.model,
                       :asset_version => model_version.model.version)
      else
        model_version.content_blobs.each do |cb|
          cb.asset = model_version.model
          cb.asset_version = model_version.version
          cb.save
        end
      end
    end
  end

  #SOP Version
  Factory.define(:sop_version,:class=>Sop::Version) do |f|
    f.association :sop
    f.after_create do |sop_version|
      sop_version.sop.version +=1
      sop_version.sop.save
      sop_version.version = sop_version.sop.version
      sop_version.title = sop_version.sop.title
      sop_version.save
    end
  end

  Factory.define(:sop_version_with_blob, :parent => :sop_version) do |f|
    f.after_create do |sop_version|
      if sop_version.content_blob.blank?
        sop_version.content_blob = Factory.create(:pdf_content_blob,
                                                  :asset => sop_version.sop,
                                                  :asset_version => sop_version.version)
      else
        sop_version.content_blob.asset = sop_version.sop
        sop_version.content_blob.asset_version = sop_version.version
        sop_version.content_blob.save
      end
    end
  end

  #DataFile Version
  Factory.define(:data_file_version,:class=>DataFile::Version) do |f|
    f.association :data_file
    f.after_create do |data_file_version|
      data_file_version.data_file.version +=1
      data_file_version.data_file.save
      data_file_version.version = data_file_version.data_file.version
      data_file_version.title = data_file_version.data_file.title
      data_file_version.save
    end
  end

  Factory.define(:data_file_version_with_blob, :parent => :data_file_version) do |f|
    f.after_create do |data_file_version|
      if data_file_version.content_blob.blank?
        data_file_version.content_blob = Factory.create(:pdf_content_blob,
                                                        :asset => data_file_version.data_file,
                                                        :asset_version => data_file_version.version)
      else
        data_file_version.content_blob.asset = data_file_version.data_file
        data_file_version.content_blob.asset_version = data_file_version.version
        data_file_version.content_blob.save
      end
    end
  end

  #Presentation Version
  Factory.define(:presentation_version,:class=>Presentation::Version) do |f|
    f.association :presentation
    f.after_create do |presentation_version|
      presentation_version.presentation.version +=1
      presentation_version.presentation.save
      presentation_version.version = presentation_version.presentation.version
      presentation_version.title = presentation_version.presentation.title
      presentation_version.save
    end
  end

  Factory.define(:presentation_version_with_blob, :parent => :presentation_version) do |f|
    f.after_create do |presentation_version|
      if presentation_version.content_blob.blank?
        presentation_version.content_blob = Factory.create(:content_blob, :original_filename => "test.pdf",
                                                           :content_type => "application/pdf",
                                                           :asset => presentation_version.presentation,
                                                           :asset_version => presentation_version)
      else
        presentation_version.content_blob.asset = presentation_version.presentation
        presentation_version.content_blob.asset_version = presentation_version.version
        presentation_version.content_blob.save
      end
    end
  end

  #Misc
  Factory.define(:group_membership) do |f|
    f.association :work_group
  end

  Factory.define(:project_position) do |f|
    f.name "A Role"
  end

  Factory.define(:pal_position,:parent=>:project_position) do |f|
    f.name "A Pal"
  end

  Factory.define(:work_group) do |f|
    f.association :project
    f.association :institution
  end

  Factory.define(:favourite_group) do |f|
    f.association :user
    f.name 'A Favourite Group'
  end

  Factory.define(:favourite_group_membership) do |f|
    f.association :person
    f.association :favourite_group
    f.access_type 1
  end

  Factory.define :discipline do |f|
    f.sequence(:title) {|n| "Discipline #{n}"}
  end

  Factory.define(:organism) do |f|
    f.title "An Organism"
  end

  Factory.define(:bioportal_concept) do |f|
    f.ontology_id "NCBITAXON"
    f.concept_uri "http://purl.obolibrary.org/obo/NCBITaxon_2287"
  end

  Factory.define(:event) do |f|
    f.title "An Event"
    f.start_date Time.now
    f.end_date 1.days.from_now
    f.projects { [Factory.build(:project)] }
    f.association :contributor, :factory => :person
  end

  Factory.define(:saved_search) do |f|
    f.search_query "cheese"
    f.search_type "All"
    f.user :factory=>:user
    f.include_external_search false
  end

#Content_blob
#either url or data should be provided for assets
  Factory.define(:content_blob) do |f|
    f.sequence(:uuid) { UUID.generate }
    f.sequence(:data) {|n| "data [#{n}]" }
    f.sequence(:original_filename) {|n| "file-#{n}"}
  end

  Factory.define(:url_content_blob, :parent => :content_blob) do |f|
    f.url "http://www.abc.com"
    f.data nil
  end

  Factory.define(:pdf_content_blob, :parent => :content_blob) do |f|
    f.original_filename "a_pdf_file.pdf"
    f.content_type "application/pdf"
    f.data  File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf","rb").read
  end

  Factory.define(:rightfield_content_blob,:parent=>:content_blob) do |f|
    f.content_type "application/excel"
    f.original_filename "rightfield.xls"
    f.data  File.new("#{Rails.root}/test/fixtures/files/rightfield-test.xls","rb").read
  end

  Factory.define(:spreadsheet_content_blob, :parent => :content_blob) do |f|
    f.content_type "application/excel"
    f.original_filename "test.xls"
  end

  Factory.define(:rightfield_annotated_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/simple_populated_rightfield.xls","rb").read
    f.content_type "application/excel"
    f.original_filename 'simple_populated_rightfield.xls'
  end

  Factory.define(:small_test_spreadsheet_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/small-test-spreadsheet.xls","rb").read
    f.content_type "application/excel"
    f.original_filename "small-test-spreadsheet.xls"
  end

  Factory.define(:tiff_content_blob,:parent=>:content_blob) do |f|
    f.content_type "image/tiff"
    f.data  File.new("#{Rails.root}/test/fixtures/files/tiff_image_test.tif","rb").read
    f.original_filename 'tiff_image_test.tif'
  end

  Factory.define(:xlsx_content_blob,:parent=>:content_blob) do |f|
    f.content_type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    f.data  File.new("#{Rails.root}/test/fixtures/files/lihua_column_index_error.xlsx","rb").read
    f.original_filename 'lihua_column_index_error.xlsx'
  end

  Factory.define(:cronwright_model_content_blob,:parent=>:content_blob) do |f|
    f.content_type "text/xml"
    f.original_filename "cronwright.xml"
    f.data  File.new("#{Rails.root}/test/fixtures/files/cronwright.xml","rb").read
  end

  Factory.define(:teusink_model_content_blob,:parent=>:content_blob) do |f|
    f.content_type "text/xml"
    f.original_filename "teusink.xml"
    f.data  File.new("#{Rails.root}/test/fixtures/files/Teusink.xml","rb").read
  end

  Factory.define(:teusink_jws_model_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/Teusink2010921171725.dat","rb").read
    f.original_filename "teusink.dat"
  end

  Factory.define(:xgmml_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/cytoscape.xgmml","rb").read
    f.original_filename "cytoscape.xgmml"
  end

  Factory.define(:non_sbml_xml_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/non_sbml_xml.xml","rb").read
    f.original_filename "non_sbml_xml.xml"
  end

  Factory.define(:invalid_sbml_content_blob,:parent=>:content_blob) do |f|
    f.data  File.new("#{Rails.root}/test/fixtures/files/invalid_sbml_xml.xml","rb").read
    f.original_filename "invalid_sbml_xml.xml"
  end

  Factory.define(:doc_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/ms_word_test.doc", "rb").read
    f.original_filename 'ms_word_test.doc'
    f.content_type 'application/msword'
  end

  Factory.define(:docx_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/ms_word_test.docx", "rb").read
    f.content_type "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    f.original_filename 'ms_word_test.docx'
  end

  Factory.define(:odt_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/openoffice_word_test.odt", "rb").read
    f.content_type 'application/vnd.oasis.opendocument.text'
    f.original_filename 'openoffice_word_test.odt'
  end

  Factory.define(:ppt_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.ppt", "rb").read
    f.content_type 'application/vnd.ms-powerpoint'
    f.original_filename "ppt_presentation.ppt"
  end

  Factory.define(:pptx_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.pptx", "rb").read
    f.content_type "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    f.original_filename 'ms_ppt_test.pptx'
  end

  Factory.define(:odp_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/openoffice_ppt_test.odp", "rb").read
    f.content_type 'application/vnd.oasis.opendocument.presentation'
    f.original_filename 'openoffice_ppt_test.odp'
  end

  Factory.define(:rtf_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/rtf_test.rtf", "rb").read
    f.content_type "application/rtf"
    f.original_filename 'rtf_test.rtf'
  end

  Factory.define(:txt_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/txt_test.txt", "rb").read
    f.content_type "text/plain"
    f.original_filename 'txt_test.txt'
  end

  Factory.define(:csv_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/csv_test.csv", "rb").read
    f.content_type "text/x-comma-separated-values"
    f.original_filename 'csv_test.csv'
  end

  Factory.define(:tsv_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/tsv_test.tsv", "rb").read
    f.content_type "text/tab-separated-values"
    f.original_filename 'tsv_test.tsv'
  end

  Factory.define(:json_content_blob, :parent => :content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/slideshare.json", "rb").read
    f.content_type "application/json"
    f.original_filename 'slideshare.json'
  end

  Factory.define(:typeless_content_blob, :parent=>:content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/file_with_no_extension", "rb").read
    f.content_type nil
    f.original_filename "file_with_no_extension"
  end

  Factory.define(:binary_content_blob,:parent=>:content_blob) do |f|
    f.data File.new("#{Rails.root}/test/fixtures/files/little_file.txt", "rb").read
    f.content_type 'application/octet-stream'
    f.original_filename "binary.bin"
  end

  Factory.define(:sample_type_template_content_blob, :parent => :content_blob) do |f|
    f.original_filename "sample-type-example.xlsx"
    f.content_type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    f.data  File.new("#{Rails.root}/test/fixtures/files/sample-type-example.xlsx","rb").read
  end

  #has more than one sample sheet, and the columns are irregular with leading empty columns and gaps
  Factory.define(:sample_type_template_content_blob2, :parent => :content_blob) do |f|
    f.original_filename "sample-type-example.xlsx"
    f.content_type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    f.data  File.new("#{Rails.root}/test/fixtures/files/sample-type-example2.xls","rb").read
  end

  Factory.define(:sample_type_populated_template_content_blob, :parent => :content_blob) do |f|
    f.original_filename "sample-type-populated.xlsx"
    f.content_type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    f.data  File.new("#{Rails.root}/test/fixtures/files/sample-type-populated.xlsx","rb").read
  end

  Factory.define(:strain_sample_data_content_blob, :parent => :content_blob) do |f|
    f.original_filename "strain-sample-data.xlsx"
    f.content_type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    f.data  File.new("#{Rails.root}/test/fixtures/files/strain-sample-data.xlsx","rb").read
  end

  Factory.define(:activity_log) do |f|
    f.action "create"
    f.association :activity_loggable, :factory => :data_file
    f.controller_name "data_files"
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
    f.studied_factor_links {[StudiedFactorLink.new(:substance => Factory(:compound))]}
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

  Factory.define(:studied_factor_link) do |f|
    f.association :substance, :factory => :compound
    f.association :studied_factor
  end

  #Experimental condition
  Factory.define(:experimental_condition) do |f|
    f.start_value 1
    f.sop_version 1
    f.association :measured_item, :factory => :measured_item
    f.association :unit, :factory => :unit
    f.association :sop, :factory => :sop
    f.experimental_condition_links {[ExperimentalConditionLink.new(:substance => Factory(:compound))]}
  end

  Factory.define(:relationship) do |f|
    f.association :subject, :factory => :model
    f.association :other_object, :factory => :model
    f.predicate Relationship::ATTRIBUTED_TO
  end

  Factory.define(:attribution, :parent => :relationship) {}

  Factory.define(:special_auth_code) do |f|
    f.association :asset, :factory => :data_file
  end

  Factory.define(:experimental_condition_link) do |f|
    f.association :substance, :factory => :compound
    f.association :experimental_condition
  end

  Factory.define :synonym do |f|
    f.name "coffee"
    f.association :substance, :factory=>:compound
  end

  Factory.define :mapping_link do |f|
    f.association :substance, :factory=>:compound
    f.association :mapping,:factory=>:mapping
  end

  Factory.define :mapping do |f|
    f.chebi_id "12345"
    f.kegg_id "6789"
    f.sabiork_id "4"
  end

  Factory.define :site_announcement do |f|
    f.sequence(:title) {|n| "Announcement #{n}"}
    f.sequence(:body) {|n| "This is the body for announcement #{n}"}
    f.association :announcer,:factory=>:admin
    f.expires_at 5.days.since
    f.email_notification false
    f.is_headline false
  end

  Factory.define :headline_announcement,:parent=>:site_announcement do |f|
    f.is_headline true
    f.title "a headline announcement"
  end

  Factory.define :feed_announcement,:parent=>:site_announcement do |f|
    f.show_in_feed true
    f.title "a feed announcement"
  end

  Factory.define :mail_announcement, :parent=>:site_announcement do |f|
    f.email_notification true
    f.title "a mail announcement"
    f.body "this is a mail announcement"
  end

  Factory.define :annotation do |f|
    f.sequence(:value) {|n| "anno #{n}"}
    f.association :source, :factory=>:person
    f.attribute_name "annotation"
  end

  Factory.define :tag,:parent=>:annotation do |f|
    f.attribute_name "tag"
  end

  Factory.define :expertise,:parent=>:annotation do |f|
    f.attribute_name "expertise"
  end

  Factory.define :tool,:parent=>:annotation do |f|
    f.attribute_name "tool"
  end

  Factory.define :text_value do |f|
    f.sequence(:text) {|n| "value #{n}"}
  end

  Factory.define :assets_creator do |f|
    f.association :asset, :factory => :data_file
    f.association :creator, :factory => :person_in_project
  end

  Factory.define :project_folder do |f|
    f.association :project, :factory=>:project
    f.sequence(:title) {|n| "project folder #{n}"}
  end

  Factory.define :worksheet do |f|
    f.content_blob { Factory.build(:spreadsheet_content_blob, :asset => Factory(:data_file))}
    f.last_row 10
    f.last_column 10
  end

  Factory.define :cell_range do |f|
    f.cell_range "A1:B3"
    f.association :worksheet
  end

  Factory.define :genotype do |f|
    f.association :gene, :factory => :gene
    f.association :modification, :factory => :modification
    f.association :strain, :factory => :strain
  end

  Factory.define :gene do |f|
    f.sequence(:title) {|n| "gene #{n}"}
  end

  Factory.define :modification do |f|
    f.sequence(:title) {|n| "modification #{n}"}
  end

  Factory.define :phenotype do |f|
    f.sequence(:description) {|n| "phenotype #{n}"}
    f.association :strain, :factory => :strain
  end

  Factory.define :publication_author do |f|
    f.sequence(:first_name) { |n| "Person#{n}" }
    f.last_name "Last"
  end

  Factory.define :scale do |f|
    f.sequence(:title) {|n| "scale #{n}"}
    f.sequence(:pos) {|n| n}
    f.sequence(:key) {|n| "scale_key_#{n}"}
    f.sequence(:image_name) {|n| "image_#{n}"}
  end

  Factory.define :post do |f|
    f.body 'post body'
    f.association :user, :factory => :user
    f.association :topic, :factory => :topic
  end

  Factory.define :topic do |f|
    f.title 'a topic'
    f.body 'topic body'
    f.association :user, :factory => :user
    f.association :forum, :factory => :forum
  end

  Factory.define :forum do |f|
    f.name 'a forum'
  end


#Workflow
  Factory.define(:workflow) do |f|
    f.sequence(:title) {|n| "A Workflow_#{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :contributor, :factory => :person
    f.association :category, :factory => :workflow_category
    f.after_create do |workflow|
      if workflow.content_blob.blank?
        workflow.content_blob = Factory.create(:enm_workflow, :asset => workflow, :asset_version=>workflow.version)
      else
        workflow.content_blob.asset = workflow
        workflow.content_blob.asset_version = workflow.version
        workflow.content_blob.save
      end
    end
  end

  Factory.define :workflow_category do |f|
    f.name 'a category'
  end

  Factory.define(:enm_workflow, :parent => :content_blob) do |f|
    f.original_filename "enm.t2flow"
    f.content_type "application/pdf"
    f.data  File.new("#{Rails.root}/test/fixtures/files/enm.t2flow","rb").read
  end

  #Run
  Factory.define(:taverna_player_run, :class => TavernaPlayer::Run) do |f|
    f.sequence(:name) {|n| "Workflow Run #{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :workflow, :factory => :workflow
    f.association :contributor, :factory => :person
  end

  Factory.define(:sweep) do |f|
    f.sequence(:name) {|n| "Sweep #{n}"}
    f.projects {[Factory.build(:project)]}
    f.association :workflow, :factory => :workflow
    f.association :contributor, :factory => :person
  end

  Factory.define(:sweep_with_runs, :parent => :sweep) do |f|
    f.after_create do |sweep|
      5.times do |i|
        Factory.build(:taverna_player_run, :sweep => sweep)
      end
    end
  end

  Factory.define(:failed_run, :parent => :taverna_player_run) do |f|
    f.status_message_key 'failed'
    f.state :failed
  end

  Factory.define(:oauth_session) do |f|
    f.association :user, :factory => :user
    f.provider 'Zenodo'
    f.access_token '123'
    f.refresh_token 'ref'
    f.expires_at (Time.now + 1.hour)
  end

  Factory.define(:sample_type) do |f|
    f.sequence(:title) {|n| "SampleType #{n}"}
  end

  Factory.define(:integer_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "Integer attribute type #{n}"}
    f.base_type 'Integer'
  end

  Factory.define(:string_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "String attribute type #{n}"}
    f.base_type 'String'
  end

  Factory.define(:float_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "Float attribute type #{n}"}
    f.base_type 'Float'
  end

  Factory.define(:datetime_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "DateTime attribute type #{n}"}
    f.base_type 'DateTime'
  end

  Factory.define(:text_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "Text attribute type #{n}"}
    f.base_type 'Text'
  end

  Factory.define(:boolean_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "Boolean attribute type #{n}"}
    f.base_type 'Boolean'
  end

  Factory.define(:strain_sample_attribute_type,:class=>SampleAttributeType) do |f|
    f.sequence(:title) {|n| "Strain attribute type #{n}"}
    f.base_type 'SeekStrain'
  end

  Factory.define(:sample_attribute) do |f|
    f.sequence(:title) {|n| "Sample attribute #{n}"}
    f.association :sample_type, :factory => :sample_type
  end

  #a string that must contain 'xxx'
  Factory.define(:simple_string_sample_attribute, :parent=>:sample_attribute) do |f|
    f.sample_attribute_type Factory(:string_sample_attribute_type,regexp:".*xxx.*")
    f.required true
  end

  Factory.define(:any_string_sample_attribute, :parent=>:sample_attribute) do |f|
    f.sample_attribute_type Factory(:string_sample_attribute_type)
    f.required true
  end


  #very simple persons name, must be 2 words, first and second word starting with capital with all letters
  Factory.define(:full_name_sample_attribute_type,:parent=>:string_sample_attribute_type) do |f|
    f.regexp  '[A-Z][a-z]+[ ][A-Z][a-z]+'
    f.title 'Full name'
  end

  #positive integer
  Factory.define(:age_sample_attribute_type,:parent=>:integer_sample_attribute_type) do |f|
    f.regexp '^[1-9]\d*$'
    f.title 'Age'
  end

  #positive float
  Factory.define(:weight_sample_attribute_type,:parent=>:float_sample_attribute_type) do |f|
    f.regexp '^[1-9]\d*[.][1-9]\d*$'
    f.title 'Weight'
  end

  #uk postcode - taken from http://regexlib.com/REDetails.aspx?regexp_id=260
  Factory.define(:postcode_sample_attribute_type,:parent=>:string_sample_attribute_type) do |f|
    f.regexp '^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? {1,2}[0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$'
    f.title 'Post Code'
  end

  Factory.define(:address_sample_attribute_type,:parent=>:text_sample_attribute_type) do |f|
    f.title 'Address'
  end

  Factory.define(:patient_sample_type,:parent=>:sample_type) do |f|
    f.title "Patient data"
    f.after_build do |type|
      # Not sure why i have to explicitly add the sample_type association
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"full name",:sample_attribute_type=>Factory(:full_name_sample_attribute_type),:required=>true,:is_title=>true, :sample_type => type)
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"age",:sample_attribute_type=>Factory(:age_sample_attribute_type),:required=>true, :sample_type => type)
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"weight",:sample_attribute_type=>Factory(:weight_sample_attribute_type),:required=>false, :sample_type => type)
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"address",:sample_attribute_type=>Factory(:address_sample_attribute_type),:required=>false, :sample_type => type)
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"postcode",:sample_attribute_type=>Factory(:postcode_sample_attribute_type),:required=>false, :sample_type => type)
    end
  end

  Factory.define(:simple_sample_type,:parent=>:sample_type) do |f|
    f.title "Simple type"
    f.after_build do |type|
      type.sample_attributes << Factory.build(:sample_attribute,:title=>"the title",:sample_attribute_type=>Factory(:string_sample_attribute_type),:required=>true,:is_title=>true, :sample_type => type)
    end
  end

Factory.define(:sample) do |f|
  f.sequence(:title) {|n| "Sample #{n}"}
  f.association :sample_type,:factory=>:simple_sample_type
  f.after_build do |sample|
    sample.set_attribute(:the_title, sample.title) if sample.data.key?(:the_title)
  end
end

Factory.define(:patient_sample, :parent=>:sample) do |f|
  f.association :sample_type, :factory => :patient_sample_type
  f.after_build do |sample|
    sample.set_attribute(:full_name, "Fred Bloggs")
    sample.set_attribute(:age, 44)
    sample.set_attribute(:weight, 88.7)
  end
end

Factory.define(:strain_sample_type, :parent=>:sample_type) do |f|
  f.title "Strain type"
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute,:title=>"name",:sample_attribute_type=>Factory(:string_sample_attribute_type),:required=>true,:is_title=>true, :sample_type => type)
    type.sample_attributes << Factory.build(:sample_attribute,:title=>"seekstrain",:sample_attribute_type=>Factory(:strain_sample_attribute_type),:required=>true, :sample_type => type)
  end
end

Factory.define(:sample_controlled_vocab_term) do |f|

end

Factory.define(:apples_sample_controlled_vocab,class:SampleControlledVocab) do |f|
  f.sequence(:title) {|n| "apples controlled vocab #{n}"}
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term,label:'Granny Smith')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term,label:'Golden Delicious')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term,label:'Bramley')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term,label:"Cox's Orange Pippin")
  end
end

Factory.define(:controlled_vocab_attribute_type,:class=>SampleAttributeType) do |f|
  f.sequence(:title) {|n| "CV attribute type #{n}"}
  f.base_type 'CV'
end

Factory.define(:apples_controlled_vocab_attribute,parent: :sample_attribute) do |f|
  f.sequence(:title) {|n| "apples controlled vocab attribute #{n}"}
  f.association :sample_controlled_vocab,:factory=>:apples_sample_controlled_vocab
  f.sample_attribute_type Factory(:controlled_vocab_attribute_type)
end

Factory.define(:apples_controlled_vocab_sample_type, :parent=>:sample_type) do |f|
  f.sequence(:title) {|n| "apples controlled vocab sample type #{n}"}
  f.after_build do |type|
    type.sample_attributes << Factory.build(:apples_controlled_vocab_attribute,title:'apples',is_title:true,required:true,sample_type:type)
  end
end
