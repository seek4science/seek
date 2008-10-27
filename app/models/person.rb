class Person < ActiveRecord::Base
  has_one :profile
  has_and_belongs_to_many :work_groups
  
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
  
end
