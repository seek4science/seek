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
            investigation = @project.investigations.select { |i| i.title == title }.first
            if investigation.nil?
              investigation = Investigation.new(title: title, projects: [@project], policy: policy.deep_copy)
            end
            investigation.position = investigation_position
            investigation_position += 1
            study_position = 1
            assay_position = 1
            investigation.save!
          end
          unless r.cell(study_index).nil? || r.cell(study_index).value.empty?
            title = r.cell(study_index).value.to_s.strip
            study = investigation.studies.select { |i| i.title == title }.first
            if study.nil?
              study = Study.new(title: title, investigation: investigation,
                                policy: policy.deep_copy )
            end
            study.position = study_position
            study_position += 1
            assay_position = 1
            study.save!
          end
          unless r.cell(assay_index).nil? || r.cell(assay_index).value.empty?
            title = r.cell(assay_index).value.to_s.strip
            assay = study.assays.select { |i| i.title == title }.first
            if assay.nil?
              assay = Assay.new(title: title, study: study,
                                policy: policy.deep_copy )
            end
            assay.position = assay_position
            assay_position += 1
            assay.assay_class = AssayClass.for_type('experimental')
            assignees = []
            assignee_indices.each do |x|
              unless r.cell(x).nil?
                assignees = assignees + r.cell(x).value.split(';')
              end
            end
            known_creators = []
            other_creators = []
            assignees.each do |a|
              creator = Person.find_by email: a
              if creator.nil?
                other_creators = other_creators + [a]
              else
                known_creators = known_creators + [creator]
              end
            end
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

      end


    end
  end
end
