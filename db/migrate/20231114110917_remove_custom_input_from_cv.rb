class RemoveCustomInputFromCv < ActiveRecord::Migration[6.1]
  def up
    # Move to Attribute first, for CV's without associated attributes the information will be lost
    controlled_vocabs = SampleControlledVocab.where(custom_input: true).includes(:sample_attributes, :extended_metadata_attributes, :template_attributes)
    controlled_vocabs.each do |controlled_vocab|
      controlled_vocab.sample_attributes.update_all(allow_cv_free_text: true)
      controlled_vocab.extended_metadata_attributes.update_all(allow_cv_free_text: true)
      controlled_vocab.template_attributes.update_all(allow_cv_free_text: true)
    end
    remove_column :sample_controlled_vocabs, :custom_input
  end

  def down
    add_column :sample_controlled_vocabs, :custom_input, :boolean, default: false

    # will only restore CV's that had attributes associated
    attributes = SampleAttribute.where(allow_cv_free_text: true)
    attributes.each do |attr|
      attr.sample_controlled_vocab&.update_column(:custom_input, :true)
    end

    attributes = ExtendedMetadataAttribute.where(allow_cv_free_text: true)
    attributes.each do |attr|
      attr.sample_controlled_vocab&.update_column(:custom_input, :true)
    end

    attributes = TemplateAttribute.where(allow_cv_free_text: true)
    attributes.each do |attr|
      attr.sample_controlled_vocab&.update_column(:custom_input, :true)
    end
  end
end
