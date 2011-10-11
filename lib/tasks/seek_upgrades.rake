require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do

  desc 'required to upgrade to 0.12.0 - converts all tags from acts_as_taggable to use acts_as_annotatable'
  task(:upgrade_tags=>:environment) do
    include ActsAsTaggableOn

    Tag.find(:all).each do |tag|

      text=tag.name
      text_value=TextValue.find_or_create_by_text(text)

      tag.taggings.each do |tagging|
        attribute = tagging.context
        attribute = "tool" if attribute=="tools"
        attribute = "tag" if attribute=="tags"
        if !attribute.nil? && attribute != "organism"
          tagger = tagging.tagger
          taggable=tagging.taggable
          if taggable.nil?
            #seed
            annotation_attribute = AnnotationValueSeed.new :value=>text_value, :attribute=>AnnotationAttribute.find_or_create_by_name(attribute)
            annotation_attribute.save!
          else
            tagger = taggable if tagger.nil? && attribute!="tag"
            unless tagger.nil?
              matches = Annotation.for_annotatable(taggable.class.name, taggable.id).with_attribute_name(attribute).by_source(tagger.class.name, tagger.id)
              matches = matches.select { |m| m.value == text_value }
              if matches.empty?
                annotation = Annotation.new :source=>tagger, :annotatable=>taggable, :value=>text_value, :attribute_name=>attribute
                disable_authorization_checks { annotation.save! }
              end

            end
          end
        end
      end
    end
    puts "Finished successfully"
  end

  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

end