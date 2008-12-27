require 'acts_as_editable'

class Person < ActiveRecord::Base
  
    acts_as_editable
    
    validates_presence_of :name
    # TODO: uncomment the following line if no 2 persons can have same name
    #validates_uniqueness_of :name

    
    validates_associated :avatars
    has_many :avatars, 
             :as => :owner,
             :dependent => :destroy
    
    has_many :group_memberships
    
    has_many :work_groups, :through=>:group_memberships

    acts_as_taggable_on :tools, :expertise
    
    has_one :user
  
    acts_as_solr(:fields => [ :first_name, :last_name ]) if SOLR_ENABLED
  
    def validates_associated(*associations)
        associations.each do |association|
            class_eval do
                validates_each(associations) do |record, associate_name, value|
                    associates = record.send(associate_name)
                    associates = [associates] unless associates.respond_to?('each')
                    associates.each do |associate|
                        if associate && !associate.valid?
                            associate.errors.each do |key, value|
                                record.errors.add(key, value)
                            end
                        end
                    end
                end
            end
        end
    end

    def people_i_may_know
        res=[]
        institutions.each do |i|
            i.people.each do |p|
                res << p unless p==self or res.include? p
            end
        end
    
        projects.each do |proj|
            proj.people.each do |p|
                res << p unless p==self or res.include? p
            end
        end
        return  res
    end
  
    def institutions
        res=[]
        work_groups.collect {|wg| res << wg.institution unless res.include?(wg.institution) }
        return res
    end
  
    def projects
        res=[]
        work_groups.collect {|wg| res << wg.project unless res.include?(wg.project) }
        return res
    end
  
    def name
        return first_name.capitalize + " " + last_name.capitalize
    end
    
    # "false" returned by this helper method won't mean that no avatars are uploaded for this person;
    # it rather means that no avatar (other than default placeholder) was selected for the person 
    def avatar_selected?
      return !avatar_id.nil?
    end
  
end
