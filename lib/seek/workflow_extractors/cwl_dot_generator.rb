module Seek
  module WorkflowExtractors
    class CWLDotGenerator
      def initialize(writer = STDOUT)
        @writer = writer
      end

      def write_line(line)
        @writer.puts(line)
      end

      def write_preamble
        # Begin graph
        write_line("digraph workflow {")

        # Overall graph style
        write_line("  graph [")
        write_line("    color = \"black\"")
        write_line("    fontname = \"Helvetica\"")
        write_line("    fontsize = \"10\"")
        write_line("    labeljust = \"left\"")
        write_line("    clusterrank = \"local\"")
        write_line("    ranksep = \"0.22\"")
        write_line("    nodesep = \"0.05\"")
        write_line("  ]")

        # Overall node style
        write_line("  node [")
        write_line("    fontname = \"Helvetica\"")
        write_line("    fontsize = \"10\"")
        write_line("    fontcolor = \"black\"")
        write_line("    shape = \"record\"")
        write_line("    height = \"0\"")
        write_line("    width = \"0\"")
        write_line("    color = \"black\"")
        write_line("    fillcolor = \"lightgoldenrodyellow\"")
        write_line("    style = \"filled\"")
        write_line("  ]")

        # Overall edge style
        write_line("  edge [")
        write_line("    fontname=\"Helvetica\"")
        write_line("    fontsize=\"8\"")
        write_line("    fontcolor=\"black\"")
        write_line("    color=\"black\"")
        write_line("    arrowsize=\"0.7\"")
        write_line("  ]")

      end

      #
      # write a graph representing a workflow to the writer
      def write_graph(structure)
        write_preamble
        write_inputs(structure)
        write_outputs(structure)
        write_steps(structure)
        write_step_links(structure)
        write_line("}")
      end

      #
      # writes a set of inputs from a workflow to the writer
      def write_inputs(structure)
        # start of subgraph with styling
        write_line("  subgraph cluster_inputs {")
        write_line("    rank = \"same\";")
        write_line("    style = \"dashed\";")
        write_line("    label = \"Workflow Inputs\";")

        # write each of the inputs as a node
        structure.inputs.each do |input|
          write_input_output(input)
        end

        # end subgraph
        write_line("}")
      end

      #
      # writes a set of outputs from a workflow to the writer
      def write_outputs(structure)
        # start of subgraph with styling
        write_line("  subgraph cluster_outputs {")
        write_line("    rank = \"same\";")
        write_line("    style = \"dashed\";")
        write_line("    labelloc = \"b\";")
        write_line("    label = \"Workflow Outputs\";")

        # write each of the outputs as a node
        structure.outputs.each do |output|
          write_input_output(output)
        end

        # end subgraph
        write_line("}")
      end

      #
      # writes a set of steps from a workflow to the writer
      def write_steps(structure)
        structure.steps.each do |step|
          label = step.name || step.nice_id

          # distinguish nested workflows
          is_subworkflow = false
          if (is_subworkflow)
            write_line("  \"#{san(step.id)}\" [label=\"#{san(label)}\", fillcolor=\"#F3CEA1\"];")
          else
            write_line("  \"#{san(step.id)}\" [label=\"#{san(label)}\"];")
          end
        end
      end

      #
      # write the links between steps for the entire model
      def write_step_links(structure)
        # write links between steps
        default_count = 1
        structure.links.each do |link|
          if link.source_id.present?
            label = link.name || link.nice_id
            write_line("  \"#{san(link.source.id)}\" -> \"#{san(link.sink.id)}\" [label=\"#{san(label)}\"];")
          elsif link.default_value.present?
            # collect default values
            label = link.name || link.nice_id
            default_label = link.default_value
            write_line("  \"default#{default_count}\" -> \"#{san(link.sink.id)}\" [label=\"#{san(label)}\"];")
            write_line("  \"default#{default_count}\" [label=\"#{san(default_label)}\", fillcolor=\"#D5AEFC\"];")
            default_count += 1
          end
        end

        # Write the links between nodes
        # Write links between outputs and penultimate steps
        structure.outputs.each do |output|
          output.sources.each do |source|
            write_line("  \"#{san(source.id)}\" -> \"#{san(output.id)}\";")
          end
        end
      end

      def write_input_output(input_output)
        # List of options for this node
        node_options = []
        node_options << "fillcolor=\"#94DDF4\""

        # Use label if it is defined
        label = input_output.name || input_output.nice_id
        unless label.blank?
          node_options << "label=\"#{san(label)}\";"
        end

        # Write the line for the node
        write_line("    \"#{san(input_output.id)}\" [#{node_options.join(",")}];")
      end

      private

      def san(str)
        str.to_s.gsub('"', '\"')
      end
    end
  end
end
