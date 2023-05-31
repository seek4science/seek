require 'test_helper'
require 'tmpdir'

class AssayTest < ActiveSupport::TestCase
  fixtures :all

  test 'shouldnt edit the assay' do
    non_admin = FactoryBot.create :user
    assert !non_admin.person.is_admin?
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert !assay.can_edit?(non_admin)
  end

  test 'to_rdf' do
    assay = FactoryBot.create :experimental_assay
    FactoryBot.create :assay_organism, assay: assay, organism: FactoryBot.create(:organism)
    pub = FactoryBot.create :publication
    FactoryBot.create :relationship, subject: assay, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub
    df = (FactoryBot.create :assay_asset, assay: assay).asset

    refute_nil df
    assert_includes assay.assets,df
    assay.reload
    assert_equal 2, assay.assets.size
    rdf = assay.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/assays/#{assay.id}"), reader.statements.first.subject

      #check includes the data file due to bug OPSK-1919
      refute_nil reader.statements.detect{|s| s.object == RDF::URI.new("http://localhost:3000/data_files/#{df.id}") && s.predicate == RDF::URI("http://jermontology.org/ontology/JERMOntology#hasPart")}
    end

    # try modelling, with tech type nil
    assay = FactoryBot.create :modelling_assay, organisms: [FactoryBot.create(:organism)], technology_type_uri: nil
    rdf = assay.to_rdf

    # assay with suggested assay/technology types
    suggested_assay_type = FactoryBot.create(:suggested_assay_type)
    suggested_tech_type = FactoryBot.create(:suggested_technology_type)
    assay = FactoryBot.create :experimental_assay, suggested_assay_type: suggested_assay_type, suggested_technology_type: suggested_tech_type
    rdf = assay.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      reader.statements.map(&:object).include? suggested_assay_type.ontology_uri
      reader.statements.map(&:object).include? suggested_tech_type.ontology_uri
    end
  end

  test 'is_asset?' do
    assert !Assay.is_asset?
    assert !assays(:metabolomics_assay).is_asset?
  end

  test 'authorization supported?' do
    assert Assay.authorization_supported?
    assert assays(:metabolomics_assay).authorization_supported?
  end

  test 'avatar_key' do
    assert_equal 'assay_experimental_avatar', assays(:metabolomics_assay).avatar_key
    assert_equal 'assay_modelling_avatar', assays(:modelling_assay_with_data_and_relationship).avatar_key
  end

  test 'is_modelling' do
    assay = FactoryBot.create(:experimental_assay)
    assert_equal 'EXP',assay.assay_class.key
    refute assay.is_modelling?

    assay = FactoryBot.create(:modelling_assay)
    assert_equal 'MODEL',assay.assay_class.key
    assert assay.is_modelling?
  end

  test 'title_trimmed' do
    User.with_current_user FactoryBot.create(:user) do
      assay = FactoryBot.create :assay,
                      contributor: User.current_user.person,
                      title: ' test'
      assay.save!
      assert_equal 'test', assay.title
    end
  end

  test 'is_experimental' do
    assay = FactoryBot.create(:experimental_assay)
    assert_equal 'EXP',assay.assay_class.key
    assert assay.is_experimental?

    assay = FactoryBot.create(:modelling_assay)
    assert_equal 'MODEL',assay.assay_class.key
    assert !assay.is_experimental?
  end

  test 'related investigation' do
    assay = assays(:metabolomics_assay)
    assert_not_nil assay.investigation
    assert_equal investigations(:metabolomics_investigation), assay.investigation
  end

  test 'related project' do
    assay = assays(:metabolomics_assay)
    assert !assay.projects.empty?
    assert assay.projects.include?(projects(:sysmo_project))
  end

  test 'validation' do
    User.with_current_user FactoryBot.create(:user) do
      assay = new_valid_assay

      assert assay.valid?

      assay.title = ''
      assert !assay.valid?

      assay.title = nil
      assert !assay.valid?

      assay.title = assays(:metabolomics_assay).title
      assert assay.valid? # can have duplicate titles

      assay.title = 'test'
      assay.assay_type_uri = nil
      assert assay.valid?
      refute_nil assay.assay_type_uri, 'uri should have been set to default in before_validation'

      assay.assay_type_uri = 'http://jermontology.org/ontology/JERMOntology#Metabolomics'

      assert assay.valid?

      assay.study = nil
      assert !assay.valid?
      assay.study = studies(:metabolomics_study)

      assay.technology_type_uri = nil
      assert assay.valid?
      refute_nil assay.technology_type_uri, 'uri should have been set to default in before_validation'

      assay.contributor = nil
      assert !assay.valid?

      assay.contributor = people(:person_for_model_owner)

      # an modelling assay can be valid without a technology type, or organism
      assay = FactoryBot.create(:modelling_assay)
      assay.technology_type_uri = nil

      assert assay.valid?
      # an experimental assay can be invalid without a sample nor a organism
      assay = FactoryBot.create(:experimental_assay)
      assay.organisms = []

      assert assay.valid?

      assay.assay_organisms = [FactoryBot.create(:assay_organism)]
      assert assay.valid?
    end
  end

  test 'validate assay and tech type' do

    assay = FactoryBot.create(:experimental_assay)
    assert assay.valid?

    # not from ontology
    assay.assay_type_uri = "http://someontology.org/science"
    refute assay.valid?

    # modelling instead of experimental
    assay.assay_type_uri = 'http://jermontology.org/ontology/JERMOntology#Metabolic_redesign'
    refute assay.valid?

    # valid assay type uri
    assay.assay_type_uri = 'http://jermontology.org/ontology/JERMOntology#Extracellular_metabolite_concentration'
    assert assay.valid?

    # not from ontology
    assay.technology_type_uri = 'http://someontology.org/science'
    refute assay.valid?

    # not a tech type
    assay.technology_type_uri = 'http://jermontology.org/ontology/JERMOntology#Metabolite_concentration'
    refute assay.valid?

    #valid tech type
    assay.technology_type_uri = 'http://jermontology.org/ontology/JERMOntology#UPLC'
    assert assay.valid?

    ## now for modelling
    assay = FactoryBot.create(:modelling_assay)
    assert assay.valid?

    # not from ontology
    assay.assay_type_uri = "http://someontology.org/science"
    refute assay.valid?

    # experimental instead of modelling
    assay.assay_type_uri = 'http://jermontology.org/ontology/JERMOntology#Enzymatic_assay'
    refute assay.valid?

    # valid assay type uri
    assay.assay_type_uri = 'http://jermontology.org/ontology/JERMOntology#Translation'
    assert assay.valid?

    assert_nil assay.technology_type_uri

    # tech type not required
    # tech type required
    assay.technology_type_uri=nil
    assert assay.valid?
    assay.technology_type_uri=''
    assert assay.valid?

    # validate with uri from suggested assay type
    assay = FactoryBot.create(:experimental_assay)
    assay.suggested_assay_type = FactoryBot.create(:suggested_assay_type)
    assert assay.valid?
    assay.suggested_assay_type = FactoryBot.create(:suggested_modelling_analysis_type)
    refute assay.valid?

    assay = FactoryBot.create(:modelling_assay)
    assay.suggested_assay_type = FactoryBot.create(:suggested_assay_type)
    refute assay.valid?
    assay.suggested_assay_type = FactoryBot.create(:suggested_modelling_analysis_type)
    assert assay.valid?

  end

  test 'publications' do
    User.with_current_user FactoryBot.create(:user) do
    one_assay_with_publication = FactoryBot.create :assay, publications: [FactoryBot.create(:publication)]

    assert_equal 1, one_assay_with_publication.publications.size
    end
  end

  test 'can delete?' do
    user = User.current_user = FactoryBot.create(:user)
    assert FactoryBot.create(:assay, contributor: user.person).can_delete?

    assay = FactoryBot.create(:assay, contributor: user.person)
    assay.associate FactoryBot.create(:data_file, contributor: user.person)
    assert !assay.can_delete?

    assay = FactoryBot.create(:assay, contributor: user.person)
    assay.associate FactoryBot.create(:sop, contributor: user.person)
    assert !assay.can_delete?

    assay = FactoryBot.create(:assay, contributor: user.person)
    assay.associate FactoryBot.create(:model, contributor: user.person)
    assert !assay.can_delete?

    pal = FactoryBot.create(:pal)
    another_project_person = FactoryBot.create(:person, project: pal.projects.first)
    # create an assay with projects = to the projects for which the pal is a pal
    assay = FactoryBot.create(:assay, contributor: another_project_person)
    assert !assay.can_delete?(pal.user)

    one_assay_with_publication = FactoryBot.create :assay, contributor: User.current_user.person, publications: [FactoryBot.create(:publication)]
    assert !one_assay_with_publication.can_delete?(User.current_user.person)
  end

  test 'assets' do
    assay = assays(:metabolomics_assay)
    assert_equal 3, assay.assets.size, 'should be 2 sops and 1 data file'
  end

  test 'sops' do
    assay = assays(:metabolomics_assay)
    assert_equal 2, assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))
  end

  test 'data files' do
    assay = assays(:metabolomics_assay)
    assert_equal 1, assay.data_files.size
    assert assay.data_files.include?(data_files(:picture))
  end

  test 'can associate data files' do
    assay = assays(:metabolomics_assay)
    User.with_current_user assay.contributor.user do
      assert_difference('Assay.find_by_id(assay.id).data_files.count') do
        assay.associate(data_files(:viewable_data_file), relationship: relationship_types(:test_data))
      end
    end
  end

  test 'relate new version of sop' do
    User.with_current_user FactoryBot.create(:user) do
      assay = FactoryBot.create :assay, contributor: User.current_user.person
      assay.save!
      sop = sops(:sop_with_all_sysmo_users_policy)
      assert_difference('Assay.find_by_id(assay.id).sops.count', 1) do
        assert_difference('AssayAsset.count', 1) do
          assay.associate(sop)
        end
      end
      assay.reload
      assert_equal 1, assay.assay_assets.size
      assert_equal sop.version, assay.assay_assets.first.version

      User.current_user = sop.contributor
      sop.save_as_new_version

      assert_no_difference('Assay.find_by_id(assay.id).sops.count') do
        assert_no_difference('AssayAsset.count') do
          assay.associate(sop)
        end
      end

      assay.reload
      assert_equal 1, assay.assay_assets.size
      assert_equal sop.version, assay.assay_assets.first.version
    end
  end

  test 'organisms association' do
    assay = assays(:metabolomics_assay)
    assert_equal 2, assay.assay_organisms.count
    assert_equal 2, assay.organisms.count
    assert assay.organisms.include?(organisms(:yeast))
    assert assay.organisms.include?(organisms(:Saccharomyces_cerevisiae))
  end

  test 'associate organism' do
    assay = FactoryBot.create(:experimental_assay)
    assay.assay_organisms.clear
    User.current_user = assay.contributor
    organism = organisms(:yeast)

    # using the general associate method for the simple case with the organism object
    assert_difference('AssayOrganism.count') do
      assay.associate(organism)
    end
    assert_equal [organism], assay.organisms
    assay.assay_organisms.clear

    # test with numeric ID
    assert_difference('AssayOrganism.count') do
      assay.associate_organism(organism.id)
    end

    assert_equal [organism], assay.organisms
    assay.assay_organisms.clear

    # with String ID
    assert_difference('AssayOrganism.count') do
      assay.associate_organism(organism.id.to_s)
    end

    assert_equal [organism], assay.organisms
    assay.assay_organisms.clear

    # with Organism object
    assert_difference('AssayOrganism.count') do
      assay.associate_organism(organism)
    end

    assert_equal [organism], assay.organisms

    # with a culture growth
    assay.assay_organisms.clear
    assay.save!
    cg = culture_growth_types(:batch)
    assert_difference('AssayOrganism.count') do
      assay.associate_organism(organism, nil, cg)
    end
    assay.reload
    assert_equal cg, assay.assay_organisms.first.culture_growth_type
  end

  test 'disassociating organisms removes AssayOrganism' do
    assay = assays(:metabolomics_assay)
    User.current_user = assay.contributor
    assert_equal 2, assay.assay_organisms.count
    assert_difference('AssayOrganism.count', -2) do
      assay.assay_organisms.clear
      assay.save!
    end
  end

  test 'associate organism with strain' do
    assay = FactoryBot.create(:assay)
    organism = FactoryBot.create(:organism)
    strain = FactoryBot.create(:strain, organism: organism)

    assert_equal organism, strain.organism
    assert_equal strain, organism.strains.find(strain.id)

    assert_equal 0, assay.assay_organisms.count, 'This test relies on this assay having no organisms'

    assert_difference('AssayOrganism.count') do
      assert_no_difference('Strain.count') do
        disable_authorization_checks { assay.associate_organism(organism, strain.id) }
      end
    end

    assay.reload
    assert_includes assay.strains, strain
    assert_includes assay.organisms, organism

    assert_no_difference('AssayOrganism.count') do
      assert_no_difference('Strain.count') do
        disable_authorization_checks { assay.associate_organism(organism, strain.id) }
      end
    end

    organism = FactoryBot.create(:organism)
    strain = FactoryBot.create(:strain, organism: organism)
    culture_growth = FactoryBot.create(:culture_growth_type)

    assert_difference('AssayOrganism.count') do
      assert_no_difference('Strain.count') do
        disable_authorization_checks { assay.associate_organism(organism, strain.id, culture_growth) }
      end
    end

    assay.reload
    assert_includes assay.strains, strain
    assert_includes assay.organisms, organism
    ao = assay.assay_organisms.find { |ao| ao.strain == strain }
    assert_equal culture_growth, ao.culture_growth_type
  end

  test 'test uuid generated' do
    a = assays(:metabolomics_assay)
    assert_nil a.attributes['uuid']
    a.save
    assert_not_nil a.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = assays(:metabolomics_assay)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  def new_valid_assay
    Assay.new(title: 'test',
              assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics',
              technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography',
              study: studies(:metabolomics_study),
              contributor: people(:person_for_model_owner),
              assay_class: assay_classes(:experimental_assay_class),
              policy: FactoryBot.create(:private_policy)
             )
  end

  test 'contributing_user' do
    assay = FactoryBot.create :assay
    assert assay.contributor
    assert_equal assay.contributor.user, assay.contributing_user
  end

  test 'assay type label from ontology or suggested assay type' do
    assay = FactoryBot.create(:experimental_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response')
    assert_equal 'Catabolic response', assay.assay_type_label

    assay = FactoryBot.create(:modelling_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Genome_scale')
    assert_equal 'Genome scale', assay.assay_type_label

    suggested_at = FactoryBot.create(:suggested_assay_type, label: 'new fluxomics')
    assay = FactoryBot.create(:experimental_assay, suggested_assay_type: suggested_at)
    assert_equal 'new fluxomics', assay.assay_type_label

    suggested_ma = FactoryBot.create(:suggested_modelling_analysis_type, label: 'new metabolism')
    assay = FactoryBot.create(:modelling_assay, suggested_assay_type: suggested_ma)
    assert_equal 'new metabolism', assay.assay_type_label
  end

  test 'technology type label from ontology or suggested technology type' do
    assay = FactoryBot.create(:experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding')
    assert_equal 'Binding', assay.technology_type_label

    suggested_tt = FactoryBot.create(:suggested_technology_type, label: 'new technology type')
    assay = FactoryBot.create(:experimental_assay, suggested_technology_type: suggested_tt)
    assert_equal 'new technology type', assay.technology_type_label
  end

  test 'default assay and tech type' do
    assay = FactoryBot.create(:experimental_assay)
    assay.assay_type_uri = nil
    assay.technology_type_uri = nil
    assay.save!
    assert_equal Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.to_s, assay.assay_type_uri
    assert_equal Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s, assay.technology_type_uri

    assay = FactoryBot.create(:modelling_assay)
    assay.assay_type_uri = nil
    assay.technology_type_uri = nil
    assay.save!
    assert_equal Seek::Ontologies::ModellingAnalysisTypeReader.instance.default_parent_class_uri.to_s, assay.assay_type_uri
    assert_nil assay.technology_type_uri
  end

  test 'assay type reader' do
    exp_assay = FactoryBot.create(:experimental_assay)
    mod_assay = FactoryBot.create(:modelling_assay)
    assert_equal Seek::Ontologies::AssayTypeReader, exp_assay.assay_type_reader.class
    assert_equal Seek::Ontologies::ModellingAnalysisTypeReader, mod_assay.assay_type_reader.class
  end

  test 'valid assay type uri' do
    assay = FactoryBot.create(:experimental_assay)
    assert assay.valid_assay_type_uri?
    assay.assay_type_uri = 'http://fish.com/onto#fish'
    assert !assay.valid_assay_type_uri?

    # modelling uri should also be invalid
    assay.assay_type_uri = Seek::Ontologies::ModellingAnalysisTypeReader.instance.default_parent_class_uri.to_s
    assert !assay.valid_assay_type_uri?
  end

  test 'valid technology type uri' do
    mod_assay = FactoryBot.create(:modelling_assay)
    exp_assay = FactoryBot.create(:experimental_assay)
    assert mod_assay.valid_technology_type_uri?
    mod_assay.technology_type_uri = Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s
    # for a modelling assay, even if it is set it is invalid
    assert !mod_assay.valid_technology_type_uri?

    assert exp_assay.valid_technology_type_uri?
    exp_assay.technology_type_uri = 'http://fish.com/onto#fish'
    assert !exp_assay.valid_technology_type_uri?
  end

  test 'destroy' do
    a = FactoryBot.create(:assay)
    refute_nil a.study
    refute_empty a.projects
    assert_difference('Assay.count', -1) do
      assert_no_difference('Study.count') do
        disable_authorization_checks do
          a.destroy
        end
      end
    end
  end

  test 'converts assay and tech suggested type uri' do
    assay_type = FactoryBot.create(:suggested_assay_type, label: 'fishy', ontology_uri: 'fish:2')
    tech_type = FactoryBot.create(:suggested_technology_type, label: 'carroty', ontology_uri: 'carrot:3')
    assay = FactoryBot.create(:experimental_assay)
    assay.assay_type_uri = assay_type.uri
    assay.technology_type_uri = tech_type.uri
    assert_equal assay_type, assay.suggested_assay_type
    assert_equal 'fishy', assay.assay_type_label
    assert_equal 'fish:2', assay.assay_type_uri

    assert_equal tech_type, assay.suggested_technology_type
    assert_equal 'carroty', assay.technology_type_label
    assert_equal 'carrot:3', assay.technology_type_uri
  end

  test 'associated samples' do
    assay = FactoryBot.create(:assay)
    sample1 = FactoryBot.create(:sample)
    sample2 = FactoryBot.create(:sample)
    sample3 = FactoryBot.create(:sample)
    df = FactoryBot.create(:data_file)
    disable_authorization_checks do
      AssayAsset.create! assay: assay, asset: sample1, direction: AssayAsset::Direction::INCOMING
      AssayAsset.create! assay: assay, asset: sample2, direction: AssayAsset::Direction::INCOMING
      AssayAsset.create! assay: assay, asset: df, direction: AssayAsset::Direction::NODIRECTION
    end

    assay = assay.reload
    assert_includes assay.samples, sample1
    assert_includes assay.samples, sample2
    refute_includes assay.samples, df

    assert_includes assay.assets, sample1
    assert_includes assay.assets, sample2
    assert_includes assay.assets, df

    refute_includes assay.samples, sample3
    refute_includes assay.assets, sample3
  end

  test 'incoming and outgoing' do
    assay = FactoryBot.create(:assay)
    df_in1 = FactoryBot.create(:data_file,title:'in1')
    df_in2 = FactoryBot.create(:data_file,title:'in2')
    sample_in1 = FactoryBot.create(:sample,title:'sample_in1')

    df_out1 = FactoryBot.create(:data_file,title:'out1')
    df_out2 = FactoryBot.create(:data_file,title: 'out2')
    sample_out1 = FactoryBot.create(:sample, title: 'sample_out1')

    df_nodir1 = FactoryBot.create(:data_file)
    sample_nodir1 = FactoryBot.create(:sample)

    df = FactoryBot.create(:data_file)
    disable_authorization_checks do
      AssayAsset.create! assay: assay, asset: df_in1, direction: AssayAsset::Direction::INCOMING
      AssayAsset.create! assay: assay, asset: df_in2, direction: AssayAsset::Direction::INCOMING
      AssayAsset.create! assay: assay, asset: sample_in1, direction: AssayAsset::Direction::INCOMING

      AssayAsset.create! assay: assay, asset: df_out1, direction: AssayAsset::Direction::OUTGOING
      AssayAsset.create! assay: assay, asset: df_out2, direction: AssayAsset::Direction::OUTGOING
      AssayAsset.create! assay: assay, asset: sample_out1, direction: AssayAsset::Direction::OUTGOING

      AssayAsset.create! assay: assay, asset: df_nodir1, direction: AssayAsset::Direction::NODIRECTION
      AssayAsset.create! assay: assay, asset: sample_nodir1, direction: AssayAsset::Direction::NODIRECTION
    end

    #sanity check
    assert_equal 5,assay.data_files.count
    assert_equal 3,assay.samples.count

    assert_equal [df_in1,df_in2,sample_in1],assay.incoming.sort_by(&:title)
    assert_equal [df_out1,df_out2,sample_out1],assay.outgoing.sort_by(&:title)

  end

  test 'validation assets' do
    assay = FactoryBot.create(:assay)
    df_1 = FactoryBot.create(:data_file,title:'validation')
    df_2 = FactoryBot.create(:data_file,title:'not validation')

    validation_type= RelationshipType.where(key:RelationshipType::VALIDATION).first || FactoryBot.create(:validation_data_relationship_type)
    disable_authorization_checks do
      AssayAsset.create! assay: assay, asset: df_1, relationship_type: validation_type
      AssayAsset.create! assay: assay, asset: df_2
    end

    assert_equal 2,assay.data_files.count
    assert_equal [df_1],assay.validation_assets
  end

  test 'simulation assets' do
    assay = FactoryBot.create(:assay)
    df_1 = FactoryBot.create(:data_file,title:'simulation')
    df_2 = FactoryBot.create(:data_file,title:'not simulation')

    validation_type= RelationshipType.where(key:RelationshipType::SIMULATION).first || FactoryBot.create(:simulation_data_relationship_type)
    disable_authorization_checks do
      AssayAsset.create! assay: assay, asset: df_1, relationship_type: validation_type
      AssayAsset.create! assay: assay, asset: df_2
    end

    assert_equal 2,assay.data_files.count
    assert_equal [df_1],assay.simulation_assets
  end

  test 'construction assets' do
    assay = FactoryBot.create(:assay)
    df_1 = FactoryBot.create(:data_file,title:'construction')
    df_2 = FactoryBot.create(:data_file,title:'not construction')

    validation_type= RelationshipType.where(key:RelationshipType::CONSTRUCTION).first || FactoryBot.create(:construction_data_relationship_type)
    disable_authorization_checks do
      AssayAsset.create! assay: assay, asset: df_1, relationship_type: validation_type
      AssayAsset.create! assay: assay, asset: df_2
    end

    assert_equal 2,assay.data_files.count
    assert_equal [df_1],assay.construction_assets
  end

  test 'clone with associations' do
    assay = FactoryBot.create(:modelling_assay, title: '123', description: 'abc', policy: FactoryBot.create(:publicly_viewable_policy))
    person = assay.contributor
    data_file = FactoryBot.create(:data_file, contributor: person)
    sample = FactoryBot.create(:sample, contributor: person)
    data_file_meta = { asset: data_file, direction: AssayAsset::Direction::INCOMING }
    sample_meta = { asset: sample, direction: AssayAsset::Direction::OUTGOING }
    publication = FactoryBot.create(:publication, contributor: person)
    model = FactoryBot.create(:model, contributor: person)
    sop = FactoryBot.create(:sop, contributor: person)
    document = FactoryBot.create(:document, contributor: person)

    disable_authorization_checks do
      assay.assay_assets.create!(data_file_meta)
      assay.assay_assets.create!(sample_meta)

      assay.publications << publication
      assay.models << model
      assay.sops << sop
      assay.documents << document
    end

    clone = assay.clone_with_associations

    assert_equal assay.title, clone.title
    assert_equal assay.description, clone.description
    assert_equal assay.projects, clone.projects
    assert_equal BaseSerializer.convert_policy(assay.policy), BaseSerializer.convert_policy(clone.policy)

    assay_asset_meta = clone.assay_assets.map { |aa| { asset: aa.asset, direction: aa.direction } }
    assert_includes assay_asset_meta, data_file_meta
    assert_includes assay_asset_meta, sample_meta
    assert_includes clone.publications, publication
    assert_includes clone.models, model
    assert_includes clone.sops, sop
    assert_includes clone.documents, document

    disable_authorization_checks { assert clone.save }
  end

  test 'has deleted contributor?' do
    item = FactoryBot.create(:assay,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:assay)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    assert item.has_deleted_contributor?
    refute item2.has_deleted_contributor?
  end

  test 'has jerm contributor?' do
    item = FactoryBot.create(:assay,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:assay)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    refute item.has_jerm_contributor?
    assert item2.has_jerm_contributor?
  end


end
