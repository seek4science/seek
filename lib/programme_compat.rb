module ProgrammeCompat
  def self.included(klass)
    klass.class_eval do

      def programmes
        projects.map { |p| p.programme }
      end

    end
  end
end
