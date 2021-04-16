require 'nokogiri'

module Seek
  
module BPMNGenerator

  def build (p)
    
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      @definitions = @xml.definitions('xmlns' => 'http://www.omg.org/spec/BPMN/20100524/MODEL',
                                     'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                     'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                                     'xmlns:flowable' => 'http://flowable.org/bpmn',
                                     'xmlns:bpmndi' => 'http://www.omg.org/spec/BPMN/20100524/DI',
                                     'xmlns:omgdc' => 'http://www.omg.org/spec/DD/20100524/DC',
                                     'xmlns:omgdi' => 'http://www.omg.org/spec/DD/20100524/DI',
                                      'targetNamespace' => '') do
        process = @xml.process do
          linkStart = xml.startEvent
          linkStart['id'] = p.id.to_s + "-Start"
          @p_link_source = linkStart['id']
          next_i = 1
          p.investigations.each do |i|
            investigation = @xml.subProcess do
              sLinkStart = xml.startEvent
              sLinkStart['id'] = 'I' + next_i.to_s + '-Start'
              @s_link_source = sLinkStart['id']

              next_s = 1
              i.studies.each do |s|
                study = @xml.subProcess do
                  aLinkStart = xml.startEvent
                  aLinkStart['id'] = 'I' + next_i.to_s + '-S' + next_s.to_s + '-Start'
                  @a_link_source = aLinkStart['id']

                  next_a = 1
                  s.assays.each do |a|
                    assay = @xml.userTask
                    assay['id'] = 'I' + next_i.to_s + '-S' + next_s.to_s + '-A' + next_a.to_s
                    next_a = next_a + 1
                    assay['name'] = a.title
                    assay['flowable:assignee'] = 'admin'
                    assay['flowable:formFieldValidation'] = 'true'

                    flow = @xml.sequenceFlow
                    flow['sourceRef'] = @a_link_source
                    flow['targetRef'] = assay.id.to_s
                    flow['id'] = flow['sourceRef'] + '-to-' + flow['targetRef'].to_s
                    @a_link_source = assay.id

                  end
                  linkEnd = xml.endEvent
                  linkEnd['id'] =  + 'I' + next_i.to_s + '-S' + next_s.to_s + '-end'

                  flow = @xml.sequenceFlow
                  flow['sourceRef'] = @a_link_source
                  flow['targetRef'] = linkEnd['id'].to_s
                  flow['id'] = flow['sourceRef'].to_xml.to_s + '-to-' + flow['targetRef'].to_xml.to_s
                end
                study['id'] = 'I' + next_i.to_s + '-S' + next_s.to_s
                next_s = next_s + 1
                study['name'] = s.title

                flow = @xml.sequenceFlow
                flow['sourceRef'] = @s_link_source
                flow['targetRef'] = study['id'].to_s
                flow['id'] = flow['sourceRef'].to_xml.to_s + '-to-' + flow['targetRef'].to_xml.to_s
                @s_link_source = study['id']
              end
              linkEnd = xml.endEvent
              linkEnd['id'] =  + 'I' + next_i.to_s + '-end'

              flow = @xml.sequenceFlow
              flow['sourceRef'] = @s_link_source
              flow['targetRef'] = linkEnd['id'].to_s
              flow['id'] = flow['sourceRef'].to_xml.to_s + '-to-' + flow['targetRef'].to_xml.to_s
            end

            investigation['id'] = 'I' + next_i.to_s
            next_i = next_i + 1
            investigation['name'] = i.title

            flow = @xml.sequenceFlow
            flow['sourceRef'] = @p_link_source
            flow['targetRef'] = investigation['id'].to_s
            flow['id'] = flow['sourceRef'].to_xml.to_s + '-to-' + flow['targetRef'].to_xml.to_s
            @p_link_source = investigation['id']
          end
          linkEnd = xml.endEvent
          linkEnd['id'] = p.id.to_s + '-End'

          flow = @xml.sequenceFlow
          flow['sourceRef'] = @p_link_source
          flow['targetRef'] = linkEnd['id'].to_xml.to_s
          flow['id'] = flow['sourceRef'].to_xml.to_s + '-to-' + flow['targetRef'].to_xml.to_s

        end
        process['id'] = p.id
        process['name'] =p.title
        process['isExecutable'] ="true"
      end
    end

  end

end

end
