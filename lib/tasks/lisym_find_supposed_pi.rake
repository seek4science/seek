require 'csv'

namespace :seek_publ_export do

  task(list_supposed_pi_for_lowscore_publ: :environment) do

    include ApplicationHelper

    file = File.join(Rails.root, 'tmp', Seek::Config.project_name + '_low_score_report.txt')
    n = 0

    File.open(file, 'w') do |low_score_report|
      # go through all project
      # projects_instance = Project.constantize
      Project.all.each do |one_project|

        warn("In project " + one_project.title)
        # find a score for each publication, keep the one bellow a thresold
        publications = one_project.publications

        publications_with_low_score = []

        publications.all.order(:created_at).each do |one_publication|

          # count the nb of related elements
          # we could do it using related_relationships but cutting it would allow us to change the weight of each
          nb_of_relation = one_publication.data_files.size
          nb_of_relation += one_publication.models.size
          nb_of_relation += one_publication.assays.size
          nb_of_relation += one_publication.studies.size
          nb_of_relation += one_publication.investigations.size
          nb_of_relation += one_publication.presentations.size

          # has_many :related_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
          #          class_name: 'Relationship', as: :other_object, dependent: :destroy, inverse_of: :other_object
          #
          # has_many :data_files, through: :related_relationships, source: :subject, source_type: 'DataFile'
          # has_many :models, through: :related_relationships, source: :subject, source_type: 'Model'
          # has_many :assays, through: :related_relationships, source: :subject, source_type: 'Assay'
          # has_many :studies, through: :related_relationships, source: :subject, source_type: 'Study'
          # has_many :investigations, through: :related_relationships, source: :subject, source_type: 'Investigation'
          # has_many :presentations, through: :related_relationships, source: :subject, source_type: 'Presentation'
          #
          warn("Nb of relation is "+ nb_of_relation.to_s + " for publication " + one_publication.title)

          if nb_of_relation < 4
            publications_with_low_score << one_publication
          end

        end

        unless publications_with_low_score.empty?
          # we found low score publications, now find the most important persons of this project

          persons = one_project.current_people

          nb_of_publication = 0

          persons_with_nb_of_publ = {}

          persons.all.each do |one_person|
            # now count the nb of publication of this project for this person
            publications_for_one_person = one_person.publication_authors

            publications_for_one_person.all.each do |one_publication_authors_for_a_person|

              publication_for_this_author = one_publication_authors_for_a_person.publication

              unless publication_for_this_author.projects.where(id: one_project.id).empty?
                nb_of_publication += 1
              end

            end

            persons_with_nb_of_publ[one_person] = nb_of_publication
          end

          low_score_report.write("\n***********\n" + one_project.title + "\n\n")

          # now sort by nb of publication and get the top 1 to 3 persons
          sortedPersons = persons_with_nb_of_publ.sort_by { |person, nb_of_publ| nb_of_publ}

          nb_to_return = [sortedPersons.size, 3].min - 1

          (0..nb_to_return).each do |i_person|
            onePerson = sortedPersons[i_person].at(0)

            warn('Would contact ' + onePerson.first_name + ' ' + onePerson.last_name)

            low_score_report.write(onePerson.first_name + ' ' + onePerson.last_name + "\n" +
                                     onePerson.email + "\n\n");
          end
          # Now the list of low score publications with their link:

          publications_with_low_score.each do |oneLowScorePubl|

            link_to_publication = URI.join(Seek::Config.site_base_host + '/', "#{oneLowScorePubl.class.name.tableize}/", oneLowScorePubl.id.to_s).to_s

            dateOfPubl = ""

            unless oneLowScorePubl.published_date.nil?
              dateOfPubl = oneLowScorePubl.published_date.strftime("#{oneLowScorePubl.published_date.day.ordinalize} %b %Y")
            end
            low_score_report.write(oneLowScorePubl.title + "\n" +
                                     dateOfPubl + "\n" +
                                     link_to_publication.to_s + "\n");
          end
        end
      end
    end
  end

end
