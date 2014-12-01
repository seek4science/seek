module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to the ISA framework
    module ISA
      def studies
        assays.map { |a| a.study }.uniq
      end

      def project_assays
        all_assays = Assay.all.select { |assay| assay.can_edit?(User.current_user) }.sort_by &:title
        all_assays = all_assays.select do |assay|
          assay.is_modelling?
        end if self.is_a? Model

        project_assays = all_assays.select { |df| User.current_user.person.projects.include?(df.project) }

        project_assays
      end

      def assay_type_titles
        assays.map { |at| at.try(:assay_type_label) }.compact
      end

      def technology_type_titles
        assays.map { |tt| tt.try(:technology_type_label) }.compact
      end
    end
  end
end
