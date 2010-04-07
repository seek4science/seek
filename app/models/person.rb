require 'acts_as_editable'
require 'grouped_pagination'

class Person < ActiveRecord::Base
  
  acts_as_editable
  
  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy

  before_save :update_first_letter
  
  grouped_pagination
    
  validates_presence_of :name,:email

  #FIXME: consolidate these regular expressions into 1 holding class
  validates_format_of :email,:with=>RFC822::EmailAddress
  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  validates_uniqueness_of :email

  validates_associated :avatars

  has_and_belongs_to_many :disciplines
  
  has_many :avatars,
    :as => :owner,
    :dependent => :destroy
    
  has_many :group_memberships
    
  has_many :work_groups, :through=>:group_memberships
  has_many :studies, :foreign_key => :person_responsible_id

  acts_as_taggable_on :tools, :expertise
    
  has_one :user   
  
  has_and_belongs_to_many :created_assets, :join_table => 'assets_creators', :class_name => 'Asset', :foreign_key => 'creator_id'
  
  acts_as_solr(:fields => [ :first_name, :last_name,:expertise,:tools,:locations, :description ]) if SOLR_ENABLED

  named_scope :without_group, :include=>:group_memberships, :conditions=>"group_memberships.person_id IS NULL"
  named_scope :registered,:include=>:user,:conditions=>"users.person_id != 0"
  named_scope :pals,:conditions=>{:is_pal=>true}

  alias_attribute :title, :name
  
  #FIXME: change userless_people to use this scope - unit tests
  named_scope :not_registered,:include=>:user,:conditions=>"users.person_id IS NULL"
  
  def self.userless_people
    p=Person.find(:all)
    return p.select{|person| person.user.nil?}
  end

  #returns an array of Person's where the first and last name match
  def self.duplicates
    people=Person.all
    dup=[]
    people.each do |p|
      peeps=people.select{|p2| p.name==p2.name}
      dup = dup | peeps if peeps.count>1
    end
    return dup
  end
    
  # get a list of people with their email for autocomplete fields
  def self.get_all_as_json
    all_people = Person.find(:all, :order => "ID asc")
    names_emails = all_people.collect{ |p| {"id" => p.id,
        "name" => (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                  (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
        "email" => (p.email.blank? ? "unknown" : p.email) } }
    return names_emails.to_json
  end

  def is_admin?
    !user.nil? && user.is_admin?
  end
  
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
  
  def locations
    # infer all person's locations from the institutions where the person is member of
    locations = self.institutions.collect { |i| i.country unless i.country.blank? }
    
    # make sure this list is unique and (if any institutions didn't have a country set) that 'nil' element is deleted
    locations = locations.uniq
    locations.delete(nil)
    
    return locations
  end

  def email_with_name
    name + " <" + email + ">"
  end
  
  def name
    firstname=first_name
    firstname||=""
    lastname=last_name
    lastname||=""
    #capitalize, including double barrelled names
    #TODO: why not just store them like this rather than processing each time? Will need to reprocess exiting entries if we do this.
    return (firstname.gsub(/\b\w/) {|s| s.upcase} + " " + lastname.gsub(/\b\w/) {|s| s.upcase}).strip
  end
    
  # "false" returned by this helper method won't mean that no avatars are uploaded for this person;
  # it rather means that no avatar (other than default placeholder) was selected for the person
  def avatar_selected?
    return !avatar_id.nil?
  end

  def roles
    roles = []
    group_memberships.each do |gm|
      roles = roles | gm.roles
    end
    return roles
  end

  def update_first_letter
    no_last_name=last_name.nil? || last_name.strip.blank?
    first_letter = strip_first_letter(last_name) unless no_last_name
    first_letter = strip_first_letter(name) if no_last_name
    #first_letter = "Other" unless ("A".."Z").to_a.include?(first_letter)
    self.first_letter=first_letter
  end
  
end
