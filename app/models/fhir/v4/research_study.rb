module Fhir
  module V4
    # Decorator for a Study to make it appear as a FHIR Study.
    class ResearchStudy
      include ActiveModel::Serialization
      delegate_missing_to :@study

      def initialize(study)
        @study = study
      end

      def identifier

        [
          {
            "use": 'official',
            # currently hardcoded.
            "system": 'https://clinicaltrials.gov/',
            "value": metadata['study_identifier']
          },
          {
            "use": 'secondary',
            "system": Seek::Util.routes.polymorphic_url(@study.class),
            "value": @study.id.to_s,
            "assigner": {
              "display": Seek::Config.instance_name
            }
          }
        ]
      end

      def status
        status_mapping = {
          'Active (recruting)' => 'active',
          'Active (not recruting)' => 'closed-to-accrual',
          'Completed' => 'completed'
        }
        status_mapping[metadata['study_status']]
      end

      def category
        category = []
        category << { 'text': metadata['study_type'] }
      end

      def condition
        study_conditions = metadata['study_condition']
        conditions = []

        study_conditions.each do |con|
          condition = {
            "coding": [
              {
                "code": con['ICD-10 code'],
                "system": "https://fhir.de/CodeSystem/bfarm/#{con['ICD-10 code']}"
              }
            ],
            "text": con['ICD-10 code']
          }
          conditions << condition
        end

        conditions
      end

      def contact
        contact = [
          {
            "name": 'Homepage',
            "telecom": [
              {
                "use": 'work',
                "system": 'url',
                "value": metadata['study_homepage']
              }
            ]
          }
        ]

        # add seek creators to the FHIR contact
        @study.assets_creators.map do |c|
          contact << {
           name: "#{c.last_name} #{c.family_name}",
           telecom: [
             system: 'url',
             value: Seek::Util.routes.person_url(@study.id)
           ]
         }
        end

        contact

      end

      def enrollment
        [
          {
            "reference": "##{resource_intitial}-enrollment"
          }
        ]
      end

      def period
        {
          "start": metadata['study_start_date'],
          "end": metadata['study_end_date']
        }
      end

      def sponsor
        {
          "reference": "##{resource_intitial}-sponsor"
        }
      end

      def principalInvestigator
        {
          "reference": "##{resource_intitial}-pi"
        }
      end

      def extension
        [
          {
            "url": '#study-acronym',
            "valueString": metadata['study_acronym']
          },
          {
            "url": '#study-sites-number',
            "valueInteger": metadata['study_sites_number']
          },
          {
            "url": '#study-dmp',
            "valueCodeableConcept": {
              "coding": [
                {
                  "code": "none",
                  "system": "http://example.com/study_dmp/",
                  "display": "No"
                }
              ]
            }
          }
        ]
      end

      def contained
        [
          {
            "resourceType": 'Group',
            "id": "#{resource_intitial}-enrollment",
            "type": 'person',
            "actual": false,
            "name": 'Intended sample size (subjects to be enrolled)',
            "quantity": metadata['study_sample_size']
          },
          {
            "resourceType": 'Organization',
            "id": "#{resource_intitial}-sponsor",
            "name": metadata['study_sponsor']
          },
          {
            "resourceType": 'Practitioner',
            "id": "#{resource_intitial}-pi",
            "name": [
              {
                "text": metadata['study_pi']
              }
            ]
          }
        ]

      end

      private
      def resource_intitial
        "#{@study.class.to_s.downcase}-#{@study.id.to_s}"
      end

      def metadata
        extended_metadata.data
      end
    end
  end
end