module Seek
  module Permissions
    class Translator
      # Using Sets instead of Arrays because lookups are much faster
      MAP = {
        view: Set.new(%i[
                        view show index search favourite favourite_delete comment comment_delete comments
                        comments_timeline rate tag items statistics tag_suggestions preview runs
                        new_object_based_on_existing_one extracted_samples extracted_samples_table current diagram
                      ]).freeze,

        download: Set.new(%i[
                            download named_download launch submit_job data execute plot explore
                            download_log download_results input output download_output download_input
                            view_result compare_versions simulate copasi_simulate diagram ro_crate ro_crate_metadata run
                          ]).freeze,

        edit: Set.new(%i[
                        edit new create update new_version create_version destroy_version edit_version
                        update_version new_item create_item edit_item update_item quick_add resolve_link
                        describe_ports retrieve_nels_sample_metadata new_git_version edit_paths update_paths
                        create_version_from_git create_version_from_ro_crate
                      ]).freeze,

        delete: Set.new(%i[
                          delete destroy destroy_item cancel destroy_samples_confirm
                        ]).freeze,

        manage: Set.new(%i[
                          manage manage_update notification read_interaction write_interaction report_problem storage_report
                          select_sample_type extraction_status persistence_status extract_samples confirm_extraction cancel_extraction
                          upload_fulltext upload_pdf soft_delete_fulltext has_matching_sample_type unzip unzip_status confirm_unzip unzip_persistence_status cancel_unzip
                          update_from_fairdata_station submit_fairdata_station fair_data_station_update_status hide_fair_data_station_update_status
                        ]).freeze
      }.freeze

      def self.translate(action)
        (MAP.find { |_, value| value.include?(action.to_sym) } || []).first
      end
    end
  end
end
