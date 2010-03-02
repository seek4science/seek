require 'uri'
class NodeWrapper
 
  attr_accessor :synonyms
  attr_accessor :definitions
  attr_accessor :type
 
  attr_accessor :id
  attr_accessor :fullId
  attr_accessor :label  
  attr_accessor :isActive
  attr_accessor :properties
  attr_accessor :version_id
  attr_accessor :child_size
  attr_accessor :children
  attr_accessor :parent_association
  attr_accessor :is_browsable

  def initialize(hash = nil, params = nil)
    if hash.nil?
      return
    end
    
    self.version_id = params[:ontology_id]
    
    hash.each do |key,value|
      if key.eql?("relations")
        self.child_size = value['ChildCount'].to_i if value['ChildCount'] 
        
        self.children = []
        if value['SubClass']
          value['SubClass'].each do |value|
            self.children << NodeWrapper.new(value, params) 
          end
        end
        self.children.sort! { |a,b| a.name.downcase <=> b.name.downcase } unless self.children.empty?
      else
        begin
          self.send("#{key}=", value)
        rescue Exception
          LOG.add :debug, "Missing '#{key}' attribute in NodeWrapper"
        end
      end
    end
    
    self.child_size = 0 if self.child_size.nil?
  end
   
   def store(key, value)
     begin
       send("#{key}=", value)
     rescue Exception
       LOG.add :debug, "Missing '#{key}' attribute in NodeWrapper"
     end
   end
   
   def name
     @label
   end
   
   def name=(value)
     @label = value
   end
   
   def to_param
     "#{URI.escape(self.id,":/?#!")}"
   end
   
   def ontology_name
     return DataAccess.getOntology(self.version_id).displayLabel
   end
   
   def ontology_id
     return DataAccess.getOntology(self.version_id).ontologyId
   end
   
   def mapping_count
     if CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount").nil?
        count = Mapping.count(:conditions=>{:source_ont => self.ontology_id, :source_id => self.id})
        CACHE.set("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount",count)
        return count
     else
        return CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount")
     end
   
   end
   
   def note_count
     if CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount").nil?
        count = MarginNote.count(:conditions=>{:ontology_id => self.ontology_id, :concept_id =>self.id})
        CACHE.set("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount",count)
        return count
     else
        return CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount")
     end

   end
      
   def networkNeighborhood(relationships = nil)         
     DataAccess.getNetworkNeighborhoodImage(self.ontology_name,self.id,relationships)
   end
   
   def pathToRootImage(relationships = nil) 
     DataAccess.getPathToRootImage(self.ontology_name,self.id,relationships)
   end
   
  # def children(relationship=["is_a"])       
  #   DataAccess.getChildNodes(self.ontology_name,self.id,relationship)
  # end
   
   def parent(relationship=["is_a"])
    
     DataAccess.getParentNodes(self.ontology_name,self.id,relationship)
   end
   
   def path_to_root
     return DataAccess.getPathToRoot(self.version_id,self.id)    
   end
   
   def to_s
     "Node_Name: #{self.name}  Node_ID: #{self.id}"
   end
end