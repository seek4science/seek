module Seek
  module Projects
    module Population

      def populate_from_spreadsheet_impl
        datafile = DataFile.find(params[:spreadsheet_id])

        policy = @project.default_policy
        
        workbook = datafile.spreadsheet
        sheet = workbook.sheets.first

        r = sheet.rows[1]

        values = r.cells.collect { |c| (c.nil? ? 'NIL' : c.value) }
        investigation_index = values.find_index('Investigation')
        study_index = values.find_index('Study')
        assay_index = values.find_index('Assay')
        description_index = values.find_index('Description')
        assignee_indices = []
        protocol_index = nil
        values.each_with_index {
          |val,i|
          if val.start_with?('Assign')
          then
            assignee_indices << i
          end
          if val.start_with?('Protocol')
          then
            protocol_index = i
          end
        }

        if investigation_index.nil? || study_index.nil? || assay_index.nil? || assignee_indices.empty?
          flash[:notice]= 'indices missing'
        end

        @project.status = 'planned'
        @project.assignee = @project.project_administrators[0]

        investigation = nil
        study = nil
        assay = nil

        investigation_position = 1
        study_position = 1
        assay_position = 1

        sheet.rows.each do |r|
          if r.nil?
            next
          end
          if r.index == 1
            next
          end

          unless r.cell(investigation_index).nil? || r.cell(investigation_index).value.empty?
            title = r.cell(investigation_index).value.to_s.strip
            description = 'Description withheld'
            s_description = r.cell(description_index)&.value&.to_s&.strip
            unless s_description.blank?
              description = s_description
            end
            investigation = @project.investigations.select { |i| i.title == title }.first
            if investigation.nil?
              investigation = Investigation.new(title: title, projects: [@project], policy: policy.deep_copy)
            end
            investigation.description = description
            assignee_emails = []
            assignee_indices.each do |x|
              unless r.cell(x).nil?
                assignee_emails = assignee_emails + r.cell(x).value.split(';')
              end
            end
            unless assignee_emails.empty?
              investigation.assignee = Person.find_by(email: assignee_emails[0])
            end
            if investigation.assignee.nil?
              investigation.assignee = @project.assignee
            end
            investigation.position = investigation_position
            investigation.status = 'planned'
            investigation_position += 1
            study_position = 1
            assay_position = 1
            investigation.save!
          end
          unless r.cell(study_index).nil? || r.cell(study_index).value.empty?
            title = r.cell(study_index).value.to_s.strip
            description = 'Description withheld'
            s_description = r.cell(description_index)&.value&.to_s&.strip
            unless s_description.blank?
              description = s_description
            end
            study = investigation.studies.select { |i| i.title == title }.first
            if study.nil?
              study = Study.new(title: title, investigation: investigation,
                                policy: policy.deep_copy )
            end
            study.description = description
            assignee_emails = []
            assignee_indices.each do |x|
              unless r.cell(x).nil?
                assignee_emails = assignee_emails + r.cell(x).value.split(';')
              end
            end
            unless assignee_emails.empty?
              study.assignee = Person.find_by(email: assignee_emails[0])
            end
            if study.assignee.nil?
              study.assignee = investigation.assignee
            end
            study.position = study_position
            study.status = 'planned'
            study_position += 1
            assay_position = 1
            study.save!
          end
          unless r.cell(assay_index).nil? || r.cell(assay_index).value.empty?
            title = r.cell(assay_index).value.to_s.strip
            description = 'Description withheld'
            s_description = r.cell(description_index)&.value&.to_s&.strip
            unless s_description.blank?
              description = s_description
            end
            assay = study.assays.select { |i| i.title == title }.first
            if assay.nil?
              assay = Assay.new(title: title, study: study,
                                policy: policy.deep_copy )
            end
            assay.description = description
            assignee_emails = []
            assignee_indices.each do |x|
              unless r.cell(x).nil?
                assignee_emails = assignee_emails + r.cell(x).value.split(';')
              end
            end
            unless assignee_emails.empty?
              assay.assignee = Person.find_by(email: assignee_emails[0])
            end
            if assay.assignee.nil?
              assay.assignee = study.assignee
            end
            assay.position = assay_position
            assay.status = 'planned'
            assay_position += 1
            assay.assay_class = AssayClass.for_type('experimental')
            known_creators = []
            other_creators = []
            assay.creators = known_creators
            assay.other_creators = other_creators.join(';')
            unless r.cell(protocol_index).nil?
              protocol_string = r.cell(protocol_index).value.to_s.strip
              protocol_id = protocol_string.split(/\//)[-1].to_i
              if protocol_string.starts_with?(Seek::Config.site_base_host)
                protocol = @project.sops.select { |p| p.id == protocol_id }.first
                unless protocol.nil?
                  assay.sops = [protocol]
                end
              end
            end
            assay.save!
          end
        end
        @project.save!
      end
end
end
end
