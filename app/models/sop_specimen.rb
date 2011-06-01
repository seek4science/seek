class SopSpecimen < ActiveRecord::Base
  belongs_to :specimen
  belongs_to :sop

  before_save :check_version
  #always returns the correct versioned asset (e.g Sop::Version) according to the stored version, or latest version if version is nil
  def versioned_asset
    s=self.sop
    s=s.parent if s.class.name.end_with?("::Version")
    if version.nil?
      s.latest_version
    else
      s.find_version(sop_version)
    end
  end

  def check_version
    if sop_version.nil? && !sop.nil? && sop.class.name.end_with?("::Version")
      self.sop_version=sop.version
    end
  end
end