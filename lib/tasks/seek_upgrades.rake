#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks => [
      :environment,
      :update_admin_assigned_roles,
      :repopulate_missing_publication_book_titles,
      :resynchronise_ontology_types,
      :convert_publication_authors,
      :clear_filestore_tmp,
      :repopulate_auth_lookup_tables,
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade => [:environment, "db:migrate", "db:sessions:clear", "tmp:clear"]) do

    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:convert_publication_authors => :environment) do
    Publication.all.each do |publication|
      if publication.publication_authors.first
        unless publication.publication_authors.first.author_index
          disable_authorization_checks do
            convert_publication_authors(publication)
            Publication.record_timestamps = false
            publication.update_creators_from_publication_authors
            publication.save!
            Publication.record_timestamps = true
          end
        end
      end
    end
  end

  def convert_publication_authors(publication)
    puts "publication #{publication.id} authors being updating"
    PublicationAuthorOrder.where(:publication_id => publication.id).each do |publication_author_order|
      publication_author = publication_author_order.author
      if publication_author.is_a?(Person)
        publication_author = PublicationAuthor.new(:publication => publication, :person => publication_author, :author_index => publication_author_order.order)
      else
        publication_author.author_index=publication_author_order.order
      end
      publication_author.save!
    end
  end

  desc("Synchronised the assay and technology types assigned to assays according to the current ontology, resolving any suggested types that have been added")
  task(:resynchronise_ontology_types=>[:environment,"tmp:create"]) do
    synchronizer = Seek::Ontologies::Synchronize.new
    synchronizer.synchronize_assay_types
    synchronizer.synchronize_technology_types
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


  task(:update_admin_assigned_roles => :environment) do
    Person.where("roles_mask > 0").each do |p|
      if p.admin_defined_role_projects.empty?
        roles = []
        (p.role_names & Person::PROJECT_DEPENDENT_ROLES).each do |role|
          projects = Seek::Config.project_hierarchy_enabled ? p.direct_projects : p.projects
          #update admin defined roles only if person has any project role in his project
          projects = projects.select { |proj| p.project_roles.map(&:group_memberships).flatten.map(&:project).include? proj }
          msg = "Updating #{p.name} for - '#{role}' - adding to #{projects.count} projects"
          msg += " and #{projects.map(&:descendants).flatten.count} sub projects" if  Seek::Config.project_hierarchy_enabled
          puts msg

          roles << [role, projects]
        end
        roles << ["admin"] if p.is_admin?
        unless roles.empty?
          Person.record_timestamps = false
          begin
            p.roles = roles
            disable_authorization_checks do
              p.save!
            end
          rescue Exception => e
            puts "Error saving #{p.name} - #{p.id}: #{e.message}"
          ensure
            Person.record_timestamps = true
          end
        end
      end
    end
  end

  private

  def read_label_map type
    file = "#{type.to_s}_label_mappings.yml"
    file = File.join(Rails.root, "config", "default_data", file)
    YAML::load_file(file)
  end

  def normalize_name(name, remove_special_character=true, replace_umlaut=false)
    #handle the characters that can't be handled through normalization
    %w[ØO].each do |s|
      name.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
    end

    codepoints = name.mb_chars.normalize(:d).split(//u)
    if remove_special_character
      ascii=codepoints.map(&:to_s).reject { |e| e.bytesize > 1 }.join
    end
    if replace_umlaut
      ascii=codepoints.map(&:to_s).collect { |e| e == '̈' ? 'e' : e }.join
    end
    ascii
  end
end
