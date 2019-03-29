# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

class AnnotationAttribute < ApplicationRecord
  validates_presence_of :name,
                        :identifier

  validates_uniqueness_of :name,
                          case_sensitive: false

  validates_uniqueness_of :identifier,
                          case_sensitive: false

  has_many :annotations,
           foreign_key: 'attribute_id'

  before_validation :set_identifier

  # If the identifier is not set, generate it before validation takes place.
  # See Annotations::Config::default_attribute_identifier_template
  # for more info.
  #
  # The rules are:
  # - if an identifier is manually set, nothing happens.
  # - if no identifier is set:
  #   - if name is enclosed in chevrons (eg: <http://...>) then the chevrons are taken out and the result is the new identifier.
  #   - if name is a URI beginning with http:// or urn: then this is used directly as the identifier.
  #   - in all other cases the identifier will be generated using the template specified by
  #     Annotations::Config::default_attribute_identifier_template, where '%s' in the template will be replaced with
  #     the transformation of 'name' through the Proc specified by Annotations::Config::attribute_name_transform_for_identifier.
  def set_identifier
    unless name.blank? || !identifier.blank?
      if name.match?(/^<.+>$/)
        self.identifier = name[1, name.length - 1].chop
      elsif name.match(/^http:\/\//) || name.match(/^urn:/)
        self.identifier = name
      else
        self.identifier = (Annotations::Config.default_attribute_identifier_template % Annotations::Config.attribute_name_transform_for_identifier.call(name))
      end
    end
  end
end
