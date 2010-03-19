require 'zlib'

class TrashRecord < ActiveRecord::Base

  # Create a new trash record for the provided record.
  def initialize (record)
    super({})
    self.trashable_type = record.class.base_class.name
    self.trashable_id = record.id
    self.data = Zlib::Deflate.deflate(Marshal.dump(serialize_attributes(record)))
  end

  # Restore a trashed record into an object. The record will not be saved.
  def restore
    restore_class = self.trashable_type.constantize
    
    # Check if we have a type field, if yes, assume single table inheritance and restore the actual class instead of the stored base class
    sti_type = self.trashable_attributes[restore_class.inheritance_column]
    if sti_type
      begin
        restore_class = self.trashable_type.send(:type_name_with_module, sti_type).constantize
      rescue NameError
        # Seems our assumption was wrong and we have no STI
      end
    end
    
    attrs, association_attrs = attributes_and_associations(restore_class, self.trashable_attributes)
    
    record = restore_class.new
    attrs.each_pair do |key, value|
      record.send("#{key}=", value)
    end
    
    association_attrs.each_pair do |association, attribute_values|
      restore_association(record, association, attribute_values)
    end
    
    return record
  end
  
  # Restore a trashed record into an object, save it, and delete the trash entry.
  def restore!
    record = self.restore
    record.save!
    self.destroy
    return record
  end

  # Attributes of the trashed record as a hash.
  def trashable_attributes
    return nil unless self.data
    uncompressed = Zlib::Inflate.inflate(self.data) rescue uncompressed = self.data # backward compatibility with uncompressed data
    Marshal.load(uncompressed)
  end
  
  # Find a trash entry by class and id.
  def self.find_trash (klass, id)
    find(:all, :conditions => {:trashable_type => klass.base_class.name, :trashable_id => id}).last
  end
  
  # Empty the trash by deleting records older than the specified maximum age. You can optionally specify
  # :only or :except in the options hash with a class or array of classes as the value to limit the trashed
  # classes which should be cleared. This is useful if you want to keep different classes for different
  # lengths of time.
  def self.empty_trash (max_age, options = {})
    sql = 'created_at <= ?'
    args = [max_age.ago]
    
    vals = options[:only] || options[:except]
    if vals
      vals = [vals] unless vals.kind_of?(Array)
      sql << ' AND trashable_type'
      sql << ' NOT' unless options[:only]
      sql << " IN (#{vals.collect{|v| '?'}.join(', ')})"
      args.concat(vals.collect{|v| v.kind_of?(Class) ? v.base_class.name : v.to_s.camelize})
    end
    
    delete_all([sql] + args)
  end
  
  private
  
  def serialize_attributes (record, already_serialized = {})
    return if already_serialized["#{record.class}.#{record.id}"]
    attrs = record.attributes.dup
    already_serialized["#{record.class}.#{record.id}"] = true
    
    record.class.reflections.values.each do |association|
      if association.macro == :has_many and [:destroy, :delete_all].include?(association.options[:dependent])
        attrs[association.name] = record.send(association.name).collect{|r| serialize_attributes(r, already_serialized)}
      elsif association.macro == :has_one and [:destroy, :delete_all].include?(association.options[:dependent])
        associated = record.send(association.name)
        attrs[association.name] = serialize_attributes(associated, already_serialized) unless associated.nil?
      elsif association.macro == :has_and_belongs_to_many
        attrs[association.name] = record.send("#{association.name.to_s.singularize}_ids".to_sym)
      end
    end
    
    return attrs
  end
  
  def attributes_and_associations (klass, hash)
    attrs = {}
    association_attrs = {}
    
    hash.each_pair do |key, value|
      if klass.reflections.include?(key)
        association_attrs[key] = value
      else
        attrs[key] = value
      end
    end
    
    return [attrs, association_attrs]
  end
  
  def restore_association (record, association, attributes)
    reflection = record.class.reflections[association]
    associated_record = nil
    if reflection.macro == :has_many
      if attributes.kind_of?(Array)
        attributes.each do |association_attributes|
          restore_association(record, association, association_attributes)
        end
      else
        associated_record = record.send(association).build
      end
    elsif reflection.macro == :has_one
      associated_record = reflection.klass.new
      record.send("#{association}=", associated_record)
    elsif reflection.macro == :has_and_belongs_to_many
      record.send("#{association.to_s.singularize}_ids=", attributes)
      return
    end
    
    return unless associated_record
    
    attrs, association_attrs = attributes_and_associations(associated_record.class, attributes)
    attrs.each_pair do |key, value|
      associated_record.send("#{key}=", value)
    end
    
    association_attrs.each_pair do |key, values|
      restore_association(associated_record, key, values)
    end
  end
  
end
