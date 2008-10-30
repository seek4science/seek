class Institution < ActiveRecord::Base
  has_many :work_groups, :dependent => :destroy
  
  #validates_presence_of :name, :country
  
  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p}
    end
    return res
  end
end
