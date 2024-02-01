module Seek
  module Projects
    module Population

      def populate_from_spreadsheet_impl
        datafile = DataFile.find(params[:spreadsheet_id])

        policy = @project.default_policy
        if policy.blank?
          flash[:error]= "Project does not have a default policy"
          return
        end

        workbook = datafile&.spreadsheet
        sheet = workbook&.sheets&.first
        if sheet.blank?
          flash[:error]= "Unable to find a sheet"
          return
        end

        r = sheet.rows[1]

        if r.cell(1).value.blank?
          flash[:error]= "Unable to find header cells in #{datafile.title}"
          return
        end

        header_cell_values = r.cells.collect { |c| (c.nil? ? 'NIL' : c.value) }
        investigation_index = header_cell_values.find_index('Investigation')
        study_index = header_cell_values.find_index('Study')
        assay_index = header_cell_values.find_index('Assay')
        description_index = header_cell_values.find_index('Description')
        assignee_indices = []
        protocol_index = nil
        header_cell_values.each_with_index do
          |val,i|
          if val&.starts_with?('Assign')
          then
            assignee_indices << i
          end
          if val&.starts_with?('Protocol')
          then
            protocol_index = i
          end
        end

        if investigation_index.blank? || study_index.blank? || assay_index.blank?
          flash[:error]= "Investigation, Study or Assay column is missing from #{datafile.title}"
          return
        end

        investigation = nil
        study = nil
        assay = nil

        investigation_position = 1
        study_position = 1
        assay_position = 1

        sheet.rows.each do |r|
          if r.blank?
            next
          end
          if r.index == 1
            next
          end

          if r.cell(investigation_index)&.value.present?
            title = r.cell(investigation_index).value.to_s.strip
            investigation = @project.investigations.select { |i| i.title == title }.first
            if investigation.blank?
              investigation = Investigation.new(title: title, projects: [@project], policy: policy.deep_copy)
            end
            set_description(investigation, r, description_index)
            investigation.position = investigation_position
            investigation_position += 1
            study_position = 1
            assay_position = 1
            investigation.save!
          end

          if r.cell(study_index)&.value.present?
            if investigation.blank?
              flash[:error]= "Study specified without Investigation in #{datafile.title} at row #{r.index}"
              return
            end
            title = r.cell(study_index).value.to_s.strip
            study = investigation.studies.select { |i| i.title == title }.first
            if study.blank?
              study = Study.new(title: title, investigation: investigation,
                                policy: policy.deep_copy )
            end
            set_description(study, r, description_index)
            study.position = study_position
            study_position += 1
            assay_position = 1
            study.save!
          end

          if r.cell(assay_index)&.value.present?
            if study.blank?
              flash[:error]= "Assay specified without Study in #{datafile.title} at row #{r.index}"
              return
            end
            title = r.cell(assay_index).value.to_s.strip
            assay = study.assays.select { |i| i.title == title }.first
            if assay.blank?
              assay = Assay.new(title: title, study: study,
                                policy: policy.deep_copy )
            end
            set_description(assay, r, description_index)
            assay.position = assay_position
            assay_position += 1
            assay.assay_class = AssayClass.experimental

            set_assignees(assay, r, assignee_indices)

            if protocol_index.present? && r.cell(protocol_index)&.value.present?
              set_protocol(assay, r, protocol_index)
            end
            assay.save!
          end
        end
        @project.save!
      end

      def set_description(object, r, description_index)
        description = 'Description withheld'
        if description_index.present?
          s_description = r.cell(description_index)&.value&.to_s&.strip
          if s_description.present?
            description = s_description
          end
        end
        object.description = description
      end

      def set_assignees(assay, r, assignee_indices)
        assignees = []
        assignee_indices.each do |x|
          if r.cell(x)&.value.present?
            assignees += r.cell(x).value.split(';')
          end
        end
        known_creators = []
        other_creators = []
        assignees.each do |a|
          creator = Person.find_by email: a
          if creator.blank?
            other_creators += [a]
          else
            known_creators += [creator]
          end
        end
        assay.creators = known_creators
        assay.other_creators = other_creators.join(';')
      end

      def set_protocol(assay, r, protocol_index)
        protocol_string = r.cell(protocol_index)&.value&.to_s.strip
        protocol_id = protocol_string.split(/\//)[-1].to_i
        if protocol_string.starts_with?(Seek::Config.site_base_host)
          protocol = @project.sops.select { |p| p.id == protocol_id }.first
          if protocol.present?
            assay.sops = [protocol]
          end
        end
      end
    end
  end
end
