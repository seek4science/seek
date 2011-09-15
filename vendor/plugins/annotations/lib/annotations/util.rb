module Annotations
  module Util
  
    # Migrate existing annotations to the v3 db schema.
    #
    # Currently it just copies all values over to TextValue entries
    # and assigns 'value' of the annotation accordingly and fixes up
    # all the versions of that annotation in a naive way.
    #
    # NOTE (1): If you need tdifferent migration behaviour, 
    # redefine this method in your app (in the same namespace).
    #
    # NOTE (2): if individual annotations fail to migrate,
    # their IDs and error info will be outputted to the console so you 
    # can inspect the issue.
    #
    # NOTE (3): this won't migrate any AnnotationValueSeed entries.
    # You will need to write another migration script/method for these.
    #
    # NOTE (4): this makes some big assumptions about your current set of
    # annotations. Please look through to make sure the logic applies.
    def self.migrate_annotations_to_v3
      Annotation.record_timestamps = false
      
      Annotation.all.each do |ann|
        begin
          ann.transaction do
            val = TextValue.new
            
            # Handle versions
            #
            # NOTE: This will take a naive approach of assuming that
            # only the 'old_value' field has been changed over time,
            # nothing else!
            
            # Build up the TextValue from the versions
            ann.versions.each do |version|
              val.text = version.old_value
              val.created_at = version.created_at unless val.created_at
              val.updated_at = version.updated_at
              val.save!
              
              val_version = val.versions(true).last
              val_version.created_at = version.created_at
              val_version.updated_at = version.updated_at
              val_version.save!
            end
            
            # Assign new TextValue to Annotation
            ann.value = val
            ann.save!
            
            # Only keep second to last version,
            # deleting others, and resetting version
            # numbers.
            ann.versions(true).each do |version|
              if version == ann.versions[-2]
                # The one we want to keep
                version.version = 1
                version.value = val
                version.save!
              else
                # Delete!
                version.destroy
              end
            end
            ann.version = 1
            ann.save!    # This shouldn't result in a new version
          end
        rescue Exception => ex
          puts "FAILED to migrate annotation with ID #{ann.id}. Error message: #{ex.message}"
        end
      end
      
      # TODO: similar kind of migration for annotation value seeds
      
      Annotation.record_timestamps = true    
    end
  
  end
  
end