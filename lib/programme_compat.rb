module ProgrammeCompat
  def self.included(klass)
    klass.class_eval do

      has_many :programmes, through: :projects

    end
  end
end
