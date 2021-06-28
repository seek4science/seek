module WorkflowInternals
  class Structure
    attr_reader :inputs, :outputs, :steps, :links

    def initialize(internals)
      @internals = internals

      @inputs = (@internals[:inputs] || []).map do |i|
        Input.new(self, **i.symbolize_keys)
      end

      @outputs = (@internals[:outputs] || []).map do |o|
        Output.new(self, **o.symbolize_keys)
      end

      @steps = (@internals[:steps] || []).map do |s|
        Step.new(self, **s.symbolize_keys)
      end

      @links = (@internals[:links] || []).map do |s|
        Link.new(self, **s.symbolize_keys)
      end
    end

    def find_source(id)
      inputs.each do |input|
        return input if input.id == id
      end

      steps.each do |step|
        return step if step.sink_ids.include?(id)
      end
    end

    def find_part(id)
      [:inputs, :outputs, :steps, :links].each do |attr|
        send(attr).each do |part|
          return part if part.id == id
        end
      end
    end

    def inspect
      "#<#{self.class.name} #{[:inputs, :outputs, :steps, :links].map { |group| "#{group}=#{send(group).length}" }.join(' ')}>"
    end
  end
end