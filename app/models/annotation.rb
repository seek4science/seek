# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

class Annotation < ApplicationRecord

  belongs_to :annotatable,
             polymorphic: true,
             inverse_of: :annotations

  belongs_to :source,
             polymorphic: true,
             inverse_of: :annotations_by

  belongs_to :value,
             polymorphic: true,
             autosave: true

  belongs_to :annotation_attribute,
             class_name: 'AnnotationAttribute',
             foreign_key: 'attribute_id'

  belongs_to :version_creator,
             class_name: Annotations::Config.user_model_name

  before_validation :process_value_generation

  validates_presence_of :source_type,
                        :source_id,
                        :annotatable,
                        :attribute_id,
                        :value_type

  validate :check_source,
           :check_value,
           :check_duplicate,
           :check_limit_per_source,
           :check_content_restrictions

  # ========================

  # Named scope to allow you to include the value records too.
  # Use this to *potentially* improve performance.
  scope :include_values, -> { includes(:value) }

  # Finder to get all annotations by a given source.
  scope :by_source, lambda { |source_type, source_id|
    where(source_type: source_type,
          source_id: source_id)
      .order('created_at DESC')
  }

  # Finder to get all annotations for a given annotatable.
  scope :for_annotatable, lambda { |annotatable_type, annotatable_id|
    where(annotatable_type: annotatable_type,
          annotatable_id: annotatable_id)
      .order('created_at DESC')
  }

  # Finder to get all annotations with a given attribute_name.
  scope :with_attribute_name, lambda { |attrib_name|
    where(annotation_attributes: { name: attrib_name })
      .joins(:annotation_attribute)
      .order('created_at DESC')
  }

  # Finder to get all annotations with one of the given attribute_names.
  scope :with_attribute_names, lambda { |attrib_names|
    conditions = [attrib_names.collect { 'annotation_attributes.name = ?' }.join(' or ')] | attrib_names
    where(conditions)
      .joins(:annotation_attribute)
      .order('created_at DESC')
  }

  # Finder to get all annotations for a given value_type.
  scope :with_value_type, lambda { |value_type|
    where(value_type: value_type)
      .order('created_at DESC')
  }

  # Helper class method to look up an annotatable object
  # given the annotatable class name and ID.
  def self.find_annotatable(annotatable_type, annotatable_id)
    return nil if annotatable_type.nil? || annotatable_id.nil?
    begin
      return annotatable_type.constantize.find(annotatable_id)
    rescue
      return nil
    end
  end

  # Helper class method to look up a source object
  # given the source class name and ID.
  def self.find_source(source_type, source_id)
    return nil if source_type.nil? || source_id.nil?
    begin
      return source_type.constantize.find(source_id)
    rescue
      return nil
    end
  end

  def attribute_name
    annotation_attribute.name
  end

  def attribute_name=(attr_name)
    attr_name = attr_name.to_s.strip
    self.annotation_attribute = AnnotationAttribute.find_or_create_by(name: attr_name)
  end

  alias original_set_value= value=
  def value=(value_in)
    # Store this raw value in a temporary variable for
    # later processing before the object is saved.
    @raw_value = value_in
  end

  def value_content
    if defined?(@raw_value)
      return @raw_value.respond_to?(:ann_content) ? @raw_value.ann_content : @raw_value
    end
    value.nil? ? '' : value.ann_content
  end

  def self.create_multiple(params, separator)
    success = true
    annotations = []
    errors = []

    annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])

    if annotatable
      values = params[:value]

      # Remove value from params hash
      params.delete('value')

      values.split(separator).each do |val|
        ann = Annotation.new(params)
        ann.value = val.strip

        if ann.save
          annotations << ann
        else
          error_text = "Error(s) occurred whilst saving annotation with attribute: '#{params[:attribute_name]}', and value: #{val} - #{ann.errors.full_messages.to_sentence}."
          errors << error_text
          logger.info(error_text)
          success = false
        end
      end
    else
      errors << "Annotatable object doesn't exist"
      success = false
    end

    [success, annotations, errors]
  end

  protected

  def ok_value_object_type?
    !value.nil? &&
      value.is_a?(ActiveRecord::Base) &&
      value.class.respond_to?(:is_annotation_value)
  end

  def process_value_generation
    if defined?(@raw_value) && !@raw_value.blank?
      val = process_value_adjustments(@raw_value)
      val = try_use_value_factory(val)

      # Now run default value generation logic
      # (as a fallback for default cases)
      case val
      when String, Symbol
        val = TextValue.new text: val.to_s
      when Numeric
        val = NumberValue.new number: val
      when ActiveRecord::Base
      # Do nothing
      else
        errors.add(:value, 'is not a valid value object')
      end

      # Set it on the ActiveRecord level now
      self.original_set_value = val

      # Reset the internal raw value too, in case this is rerun
      @raw_value = val
    end

    true
  end

  def process_value_adjustments(value_in)
    value_out = value_in

    attr_name = attribute_name.downcase

    value_in = value_out.to_s if value_out.is_a?(Symbol)

    # Make lowercase or uppercase if required
    if value_out.is_a?(String)
      if Annotations::Config.attribute_names_for_values_to_be_downcased.include?(attr_name)
        value_out = value_out.downcase
      end
      if Annotations::Config.attribute_names_for_values_to_be_upcased.include?(attr_name)
        value_out = value_out.upcase
      end

      # Apply strip text rules
      Annotations::Config.strip_text_rules.each do |attr, strip_rules|
        if attr_name == attr.downcase
          if strip_rules.is_a? Array
            strip_rules.each do |s|
              value_out = value_out.gsub(s, '')
            end
          elsif strip_rules.is_a?(String) || strip_rules.is_a?(Regexp)
            value_out = value_out.gsub(strip_rules, '')
          end
        end
      end
    end

    value_out
  end

  def try_use_value_factory(value_in)
    attr_name = attribute_name.downcase

    if Annotations::Config.value_factories.key?(attr_name)
      return Annotations::Config.value_factories[attr_name].call(value_in)
    else
      return value_in
    end
  end

  # ===========
  # Validations
  # -----------

  def check_source
    if Annotation.find_source(source_type, source_id).nil?
      errors.add(:source_id, "doesn't exist")
      false
    else
      true
    end
  end

  def check_value
    ok = true
    if value.nil?
      errors.add(:value, 'object must be provided')
      ok = false
    elsif !ok_value_object_type?
      errors.add(:value, 'must be a valid annotation value object')
      ok = false
    else
      attr_name = attribute_name.downcase
      if Annotations::Config.valid_value_types.key?(attr_name) &&
         ![Annotations::Config.valid_value_types[attr_name]].flatten.include?(value.class.name)
        errors[:base] << "Annotation value is of an invalid type for attribute name: '#{attr_name}'. Provided value is a #{value.class.name}."
        ok = false
      end
    end

    ok
  end

  # This method checks whether duplicates are allowed for this particular annotation type (ie:
  # for the attribute that this annotation belongs to).
  # If not allowed, it checks for a duplicate existing annotation and fails if one does exist.
  def check_duplicate
    if ok_value_object_type?
      attr_name = attribute_name.downcase
      if Annotations::Config.attribute_names_to_allow_duplicates.include?(attr_name)
        return true
      else
        if value.class.has_duplicate_annotation?(self)
          errors[:base] << 'This annotation already exists and is not allowed to be created again.'
          return false
        else
          return true
        end
      end
    end
  end

  # This method uses the 'limits_per_source config' setting to check whether a limit has been reached.
  #
  # NOTE: this check is only carried out on new records, not records that are being updated.
  def check_limit_per_source
    attr_name = attribute_name.downcase
    if new_record? && Annotations::Config.limits_per_source.key?(attr_name)
      options = Annotations::Config.limits_per_source[attr_name]
      max = options[0]
      can_replace = options[1]

      if (found_annotatable = Annotation.find_annotatable(annotatable_type, annotatable_id)).nil?
        return true
      else
        anns = found_annotatable.annotations_with_attribute_and_by_source(attr_name, source)

        if anns.length >= max
          errors[:base] << 'The limit has been reached for annotations with this attribute and by this source.'
          return false
        else
          return true
        end
      end
    else
      return true
    end
  end

  def check_content_restrictions
    if ok_value_object_type?
      attr_name = attribute_name.downcase
      content_to_check = value_content
      if Annotations::Config.content_restrictions.key?(attr_name)
        options = Annotations::Config.content_restrictions[attr_name]

        case options[:in]
        when Array
          if content_to_check.is_a?(String)
            if options[:in].map(&:downcase).include?(content_to_check.downcase)
              return true
            else
              errors[:base] << (options[:error_message])
              return false
            end
          else
            if options[:in].include?(content_to_check)
              return true
            else
              errors[:base] << (options[:error_message])
              return false
            end
          end

        when Range
          # Need to take into account that "a_string".to_i == 0
          if content_to_check == '0'
            if options[:in] === 0
              return true
            else
              errors[:base] << (options[:error_message])
              return false
            end
          else
            if options[:in] === content_to_check.to_i
              return true
            else
              errors[:base] << (options[:error_message])
              return false
            end
          end

        else
          return true
        end
      else
        return true
      end
    end
  end

  # ===========
end
