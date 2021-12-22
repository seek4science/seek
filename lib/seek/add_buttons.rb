module Seek
  # defines what can be added to a particular item, and the params used
  class AddButtons
    DEFINITIONS = {
      'Investigation' => [[Study, 'study[investigation_id]']],
      'Study' => [[Assay, 'assay[study_id]']],
      'Modelling Analysis' => [[DataFile, 'data_file[assay_assets_attributes[][assay_id]]'],
                               [Document, 'document[assay_assets_attributes[][assay_id]]'],
                               [Sop, 'sop[assay_assets_attributes[][assay_id]]'],
                               [Model, 'model[assay_assets_attributes[][assay_id]]']],
      'Experimental Assay' => [[DataFile, 'data_file[assay_assets_attributes[][assay_id]]'],
                               [Document, 'document[assay_assets_attributes[][assay_id]]'],
                               [Sop, 'sop[assay_assets_attributes[][assay_id]]']],
      'Model' => [[Assay, 'assay[model_ids][]']],
      'Sop' => [[Assay, 'assay[sop_ids][]']],
      'Publication' => [[Event, 'event[publication_ids][]'],
                        [Investigation, 'investigation[publication_ids][]'],
                        [Study, 'study[publication_ids][]'],
                        [Assay, 'assay[publication_ids][]'],
                        [DataFile, 'data_file[publication_ids][]'],
                        [Model, 'model[publication_ids][]'],
                        [Presentation, 'presentation[publication_ids][]']],
      'Document' => [[Event, 'event[document_ids][]'],
                     [Assay, 'assay[document_ids][]']],
      'Presentation' => [[Event, 'event[presentation_ids][]']],
      'Event' => [[DataFile, 'data_file[event_ids][]'],
                  [Presentation, 'presentation[event_ids][]'],
                  [Document, 'document[event_ids][]']],
      'DataFile' => [[Assay, 'assay[data_files_attributes[][asset_id]]'],
                     [Event, 'event[data_file_ids][]']],
      'Workflow' => [[Document, 'document[workflow_ids][]'],
                     [Presentation, 'presentation[workflow_ids][]']]
    }.freeze

    def self.add_dropdown_for(item)
      DEFINITIONS.key?(resolve_key(item))
    end

    def self.add_for_item(item)
      DEFINITIONS[resolve_key(item)]
    end

    def self.resolve_key(item)
      if item.is_a?(Assay) # assay is special due to its different behaviour based on type
        item.assay_class.long_key
      else
        item.class.name
      end
    end
  end
end
