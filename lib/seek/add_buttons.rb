module Seek
  # defines what can be added to a particular item, and the params used
  class AddButtons

    DEFINITIONS = {
        'Investigation'=>[[Study,'study[investigation_id]']],
        'Study'=>[[Assay,'assay[study_id]']],
        'Assay'=>[[DataFile,'data_file[assay_assets_attributes[][assay_id]]'],
                  [Document, 'document[assay_assets_attributes[][assay_id]]'],
                  [Sop,'sop[assay_assets_attributes[][assay_id]]'],
                  [Model,'model[assay_assets_attributes[][assay_id]]']],
        'Model'=>[[Assay,'assay[model_ids][]']],
        'Sop'=>[[Assay,'assay[sop_ids][]']],
        'Publication'=>[[Event,'event[publication_ids][]'],
                        [Investigation,'investigation[publication_ids][]'],
                        [Study,'study[publication_ids][]'],
                        [Assay,'assay[publication_ids][]'],
                        [DataFile,'data_file[publication_ids][]'],
                        [Model,'model[publication_ids][]'],
                        [Presentation,'presentation[publication_ids][]']
        ]
    }.freeze

    def self.add_dropdown_for(item)
      DEFINITIONS.has_key?(item.class.name)
    end

    def self.add_for_item(item)
      DEFINITIONS[item.class.name]
    end

  end
end