#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_assay_types_from_ontology,
            :update_technology_types_from_ontology,
             :update_top_level_assay_type_titles,
            :resynchronise_assay_types,
            :resynchronise_technology_types,
            :increase_sheet_empty_rows,
            :clear_filestore_tmp,
            :repopulate_missing_publication_book_titles,

            :clean_up_sop_specimens,
            :repopulate_auth_lookup_tables,
            :drop_solr_index
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear"]) do

    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:drop_solr_index=>:environment) do
    dir = File.join(Rails.root,"solr","data")
    if File.exists?(dir)
      FileUtils.remove_dir(dir)
    end
  end

  task(:clean_up_sop_specimens=>:environment) do
    broken = SopSpecimen.all.select{|ss| ss.sop.nil? || ss.specimen.nil?}
    disable_authorization_checks do
      broken.each{|b| b.destroy}
    end
  end


  desc("Increase the min rows from 10 to 35")
  task(:increase_sheet_empty_rows => :environment) do
    worksheets = Worksheet.all.compact
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    worksheets.each do |ws|
      if ws.last_row < min_rows
        ws.last_row = min_rows
        ws.save
      end
    end
  end
   desc "update assay types from ontology"
   task :update_assay_types_from_ontology => :environment  do

     #fix spelling error in earlier seed data
           type = AssayType.find_by_title("flux balanace analysis")
           unless type.nil?
             type.title = "flux balance analysis"
             type.save
           end
      # add term_uri to root: assay_types
      root = AssayType.find_by_title("assay types")
      root.term_uri =  "http://www.mygrid.org.uk/ontology/JERMOntology#Assay_type"
      root.source_path = Seek::Ontologies::AssayTypeReader.instance.ontology_file
      root.save!
      #some title:label mapping

      label_map = read_label_map(:assay_types)

     assay_type_label_hash =  Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label
     assay_type_label_hash.each do |label, clz|
           term_uri = clz.uri.to_s
           title =  label_map.key(label).nil? ? label : label_map.key(label)
           source_path = Seek::Ontologies::AssayTypeReader.instance.ontology_file

           parents = []
           clz.parents.each do |p|
                parent = AssayType.find_by_term_uri(p.uri.to_s)
                parent ||= AssayType.find_by_title(p.label)
                if parent.nil?
                  parent = AssayType.create :title=> p.label, :term_uri=> p.uri.to_s
                  puts "parent #{parent.title} was created for assay type #{title}".red
                end
                parents << parent
           end


           at = AssayType.find_by_term_uri term_uri
           at ||= AssayType.where(["lower(title)=?",label.downcase]).first
           at ||= AssayType.where(["lower(title)=?",label.gsub("_"," ").downcase]).first
           at ||= AssayType.where(["lower(title)=?",title.downcase]).first
           at ||= AssayType.where(["lower(title)=?",title.gsub("_"," ").downcase]).first
         if at
           puts "Assay Type Title: #{at.title} || label is #{label} || || label_map is #{label_map.key(label)}" if at.title != label || at.title != title
           at.source_path = source_path
           at.term_uri = term_uri
           at.parents = parents

           if at.changed?
             puts "Assay Type: #{at.title} was updated, changes are: #{at.changes}".yellow
           end
           at.save!
         else
           at = AssayType.new :title => title.gsub("_"," "), :term_uri => term_uri, :source_path => source_path

            at.parents = parents
           at.save!
           puts "title: #{at.title}, label: #{title}"
           puts "uri: #{at.term_uri}, uri: #{term_uri}"
           puts "parents: #{at.parents.map(&:title).join(", ")}, parents: #{clz.parents.map(&:label).join(", ")}"
           puts "Assay Type: #{label} was created with uri #{term_uri}, and parents: #{at.parents.map(&:title).join(", ")}".red
         end


     end

           modelling_analysis_label_hash = Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_label

           modelling_analysis_label_hash.each do |label, clz|
             term_uri = clz.uri.to_s
             title = label_map.key(label).nil? ? label : label_map.key(label)
             source_path = Seek::Ontologies::ModellingAnalysisTypeReader.instance.ontology_file

             parents = []
             clz.parents.each do |p|
               parent = AssayType.find_by_term_uri(p.uri.to_s)
               parent ||= AssayType.find_by_title(p.label)
               if parent.nil?
                 parent = AssayType.create :title => p.label, :term_uri => p.uri.to_s
                 puts "parent #{parent.title} was created for assay type #{title}".red
               end
               parents << parent
             end

             at = AssayType.find_by_term_uri term_uri
             at ||= AssayType.where(["lower(title)=?", label.downcase]).first
             at ||= AssayType.where(["lower(title)=?", label.gsub("_", " ").downcase]).first
             at ||= AssayType.where(["lower(title)=?", title.downcase]).first
             at ||= AssayType.where(["lower(title)=?", title.gsub("_", " ").downcase]).first
             if at
               puts "Assay Type Title: #{at.title} || label is #{label} || || label_map is #{label_map.key(label)}" if at.title != label || at.title != title
               at.source_path = source_path
               at.term_uri = term_uri
               at.parents = parents
               if at.changed?
                 puts "Assay Type: #{at.title} was updated, changes are: #{at.changes}".yellow
               end
               at.save!
             else
               at = AssayType.new :title => title.gsub("_", " "), :term_uri => term_uri, :source_path => source_path
               at.parents = parents
               at.save!
               puts "title: #{at.title}, label: #{title}"
               puts "uri: #{at.term_uri}, uri: #{term_uri}"
               puts "parents: #{at.parents.map(&:title).join(", ")}, parents: #{clz.parents.map(&:label).join(", ")}"
               puts "Assay Type: #{label} was created with uri #{term_uri}, and parents: #{at.parents.map(&:title).join(", ")}".red
             end
           end


     # add default parents to two sub-roots
           exp_id = AssayType.experimental_assay_type_id
           assay_type = AssayType.find(exp_id)
           assay_type.parents = [AssayType.ontology_root]
           assay_type.save!

           mod_id = AssayType.modelling_assay_type_id
           assay_type = AssayType.find(mod_id)
           assay_type.parents = [AssayType.ontology_root]
           assay_type.save!
   end

  desc "update technology types from ontology"
     task :update_technology_types_from_ontology => :environment  do
       # add term_uri to root: technology_types
             root = TechnologyType.find_by_title("technology")
             root.term_uri =  "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
             root.source_path = Seek::Ontologies::TechnologyTypeReader.instance.ontology_file
             root.save!
             #some title:label mapping

             label_map = read_label_map(:technology_types)

             technology_type_label_hash =  Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label
             technology_type_label_hash.each do |label, clz|
                  term_uri = clz.uri.to_s
                  title =  label_map.key(label).nil? ? label : label_map.key(label)
                  source_path = Seek::Ontologies::TechnologyTypeReader.instance.ontology_file

                  parents = []
                  clz.parents.each do |p|
                       parent = TechnologyType.find_by_term_uri(p.uri.to_s)
                       parent ||= TechnologyType.find_by_title(p.label)
                       if parent.nil?
                         parent = TechnologyType.create :title=> p.label, :term_uri=> p.uri.to_s
                         puts "parent #{parent.title} was created for Technology type #{title}".red
                       end
                       parents << parent
                  end


                  tt = TechnologyType.find_by_term_uri term_uri
                  tt ||= TechnologyType.where(["lower(title)=?",label.downcase]).first
                  tt ||= TechnologyType.where(["lower(title)=?",label.gsub("_"," ").downcase]).first
                  tt ||= TechnologyType.where(["lower(title)=?",title.downcase]).first
                  tt ||= TechnologyType.where(["lower(title)=?",title.gsub("_"," ").downcase]).first
                if tt
                  puts "Technology Type Title: #{tt.title} || label is #{label} || || label_map is #{label_map.key(label)}" if tt.title != label || tt.title != title
                  tt.source_path = source_path
                  tt.term_uri = term_uri
                  tt.parents = parents

                  if tt.changed?
                    puts "Technology Type: #{tt.title} was updated, changes are: #{tt.changes}".yellow
                  end
                  tt.save!
                else
                  tt = TechnologyType.new :title => title.gsub("_"," "), :term_uri => term_uri, :source_path => source_path

                   tt.parents = parents
                  tt.save!
                  puts "title: #{tt.title}, label: #{title}"
                  puts "uri: #{tt.term_uri}, uri: #{term_uri}"
                  puts "parents: #{tt.parents.map(&:title).join(", ")}, parents: #{clz.parents.map(&:label).join(", ")}"
                  puts "Technology Type: #{label} was created with uri #{term_uri}, and parents: #{tt.parents.map(&:title).join(", ")}".red
                end


            end
     end


   desc "adds the term uri's to assay types"
    task :add_term_uris_to_assay_types=>:environment do
      #fix spelling error in earlier seed data
      type = AssayType.find_by_title("flux balanace analysis")
      unless type.nil?
        type.title = "flux balance analysis"
        type.save
      end

      yamlfile=File.join(Rails.root,"config","default_data","assay_types.yml")
      yaml=YAML.load_file(yamlfile)
      yaml.keys.each do |k|
        title = yaml[k]["title"]
        uri = yaml[k]["term_uri"]
        unless uri.nil?
          assay_type = AssayType.where(["lower(title)=?",title.downcase]).first

          unless assay_type.nil?
                assay_type.term_uri = uri
                assay_type.save!
          end
        else
          puts "No uri defined for assaytype #{title} so skipping adding term"
        end

      end
    end

    desc "adds the term uri's to technology types"
    task :add_term_uris_to_technology_types=>:environment do
      yamlfile=File.join(Rails.root,"config","default_data","technology_types.yml")
      yaml=YAML.load_file(yamlfile)
      yaml.keys.each do |k|
        title = yaml[k]["title"]
        uri = yaml[k]["term_uri"]
        unless uri.nil?
          tech_type = TechnologyType.where(["lower(title)=?",title.downcase]).first
          unless tech_type.nil?
                tech_type.term_uri = uri
                tech_type.save
          end
        else
          puts "No uri defined for Technology Type #{title} so skipping adding term"
        end

      end
    end


  task(:update_top_level_assay_type_titles=>:environment) do
    exp_id = AssayType.experimental_assay_type_id
    assay_type = AssayType.find(exp_id)
    assay_type.title="generic experimental assay"
    assay_type.parents = AssayType.find_all_by_title("assay types")
    assay_type.save!

    mod_id = AssayType.modelling_assay_type_id
    assay_type = AssayType.find(mod_id)
    assay_type.title="generic modelling analysis"
    assay_type.parents = AssayType.find_all_by_title("assay types")
    assay_type.save!
  end

   desc("Synchronised the assay types assigned to assays according to the current ontology")
  task(:resynchronise_assay_types => :environment) do

    label_map = read_label_map(:assay_types)

    Assay.record_timestamps = false

    Assay.all.each do |assay|
      assay_type_label_hash = assay.assay_type_reader.class_hierarchy.hash_by_label

      label = assay[:assay_type_label].try(:downcase)

      unless label.nil?
        #check to see if the label can resolve to a uri
        resolved_uri = assay_type_label_hash[label].try(:uri).try(:to_s)

        #if the resolved uri is nil try a mapped label
        resolved_uri ||= assay_type_label_hash[label_map[label]].try(:uri).try(:to_s)

        #if the uri is resolved, update the stored uri and remove the label
        unless resolved_uri.nil?
          if assay.assay_type_uri != resolved_uri
            assay.assay_type_uri = resolved_uri
            puts "the assay type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
          end
          assay.assay_type_label = nil
        end

      end

      unless assay.valid_assay_type_uri?
        #if the uri is still invalid, we need to set it to the default
        uri = assay[:assay_type_uri]
        puts "the assay type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_assay_type_uri!
      end

      unless assay.suggested_assay_type_label.nil?
         puts "The Assay #{assay.id} has a suggested assay type label of #{assay.assay_type_label.inspect}, currently attached to the parent URI #{assay.assay_type_uri.inspect}".yellow
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end

    end
    Assay.record_timestamps = true
  end

  desc("Synchronised the technology types assigned to assays according to the current ontology")
  task(:resynchronise_technology_types => :environment) do
    Assay.record_timestamps = false

    tech_type_label_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label

    label_map = read_label_map(:technology_types)

    Assay.all.each do |assay|
      unless assay.is_modelling?
        label = assay[:technology_type_label].try(:downcase)
        unless label.nil?

          resolved_uri = tech_type_label_hash[label].try(:uri).try(:to_s)

          #if the resolved uri is nil try a mapped label
          resolved_uri ||= tech_type_label_hash[label_map[label]].try(:uri).try(:to_s)

          #if the uri is resovled, update the stored uri and remove the label
          unless resolved_uri.nil?
            if assay.technology_type_uri != resolved_uri
              assay.technology_type_uri = resolved_uri
              puts "the technology type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
            end
            assay.technology_type_label = nil
          end

        end
      else
        assay.technology_type_uri = nil
      end
      unless assay.valid_technology_type_uri?
        uri = assay[:technology_type_uri]
        puts "the technology type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{title.inspect} and URI was #{uri.inspect}".red
        assay.use_default_technology_type_uri!
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end
      unless assay.suggested_technology_type_label.nil?
        puts "The Assay #{assay.id} has a suggested technology type label of #{assay.technology_type_label.inspect}, currently attached to the parent URI #{assay.technology_type_uri.inspect}".yellow
      end
    end
    Assay.record_timestamps = true
  end

  desc "repopulate missing book titles for publications"
    task(:repopulate_missing_publication_book_titles => :environment) do
      disable_authorization_checks do
        Publication.all.select { |p| p.publication_type ==3 && p.journal.blank? }.each do |pub|
          if pub.doi
            query = DoiQuery.new(Seek::Config.crossref_api_email)
            result = query.fetch(pub.doi)
            unless result.nil? || !result.error.nil?
              pub.extract_doi_metadata(result)
              pub.save
            end
          end
        end
      end
    end

  private

  def read_label_map type
    file = "#{type.to_s}_label_mappings.yml"
    file = File.join(Rails.root,"config","default_data",file)
    YAML::load_file(file)
  end

  def normalize_name(name, remove_special_character=true, replace_umlaut=false)
    #handle the characters that can't be handled through normalization
    %w[ØO].each do |s|
      name.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
    end

    codepoints = name.mb_chars.normalize(:d).split(//u)
    if remove_special_character
      ascii=codepoints.map(&:to_s).reject{|e| e.bytesize > 1}.join
    end
    if replace_umlaut
      ascii=codepoints.map(&:to_s).collect {|e| e == '̈' ? 'e' : e}.join
    end
    ascii
  end


  
end
