#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
inputs:
  rulesfile: File
  sourcefile: File
  sinkfile: File
  reverse: boolean?
  max-steps: int?

outputs:
  compounds:
    type: File
    outputSource: rp2paths/compounds
  reactions:
    type: File
    outputSource: rp2paths/reactions
  sinks:
    type: File
    outputSource: rp2paths/sinks

steps:
  rp2:
    run: ../tools/RetroPath2-cwl/tool.cwl
    in:
      input.rulesfile: rulesfile
      input.sourcefile: sourcefile
      input.sinkfile: sinkfile
      input.max-steps: max-steps
    out: [solutionfile]

  rp2paths:
    run: ../tools/rp2paths-cwl/tool.cwl
    in:
      infile: rp2/solutionfile
      reverse: reverse
    out: [compounds, reactions, sinks]
