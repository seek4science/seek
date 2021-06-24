{
    "$graph": [
        {
            "class": "CommandLineTool",
            "baseCommand": null,
            "arguments": [
                "output.dir=$(runtime.outdir)"
            ],
            "hints": [
                {
                    "dockerPull": "ibisba/retropath2:latest",
                    "class": "DockerRequirement"
                }
            ],
            "inputs": [
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "inputBinding": {
                        "prefix": "input.cofsfile=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.cofsfile"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.dmax=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.dmax"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.dmin=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.dmin"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.max-steps=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.max-steps"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.mwmax-cof=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.mwmax-cof"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.mwmax-source=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.mwmax-source"
                },
                {
                    "type": "File",
                    "inputBinding": {
                        "prefix": "input.rulesfile=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.rulesfile"
                },
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "inputBinding": {
                        "prefix": "input.sinkfile=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.sinkfile"
                },
                {
                    "type": "File",
                    "inputBinding": {
                        "prefix": "input.sourcefile=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.sourcefile"
                },
                {
                    "type": [
                        "null",
                        "string"
                    ],
                    "inputBinding": {
                        "prefix": "input.std_mode=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.std_mode"
                },
                {
                    "type": [
                        "null",
                        "string"
                    ],
                    "inputBinding": {
                        "prefix": "input.stereo_mode=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.stereo_mode"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "inputBinding": {
                        "prefix": "input.topx=",
                        "separate": false
                    },
                    "id": "#tool.cwl/input.topx"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "outputBinding": {
                        "glob": "results.csv"
                    },
                    "id": "#tool.cwl/solutionfile"
                },
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "outputBinding": {
                        "glob": "source-in-sink.csv"
                    },
                    "id": "#tool.cwl/sourceinsinkfile"
                },
                {
                    "type": "File",
                    "id": "#tool.cwl/stdout",
                    "outputBinding": {
                        "glob": "output.txt"
                    }
                }
            ],
            "stdout": "output.txt",
            "id": "#tool.cwl"
        },
        {
            "class": "CommandLineTool",
            "baseCommand": [
                "RP2paths.py",
                "all"
            ],
            "hints": [
                {
                    "dockerPull": "ibisba/rp2paths",
                    "class": "DockerRequirement"
                },
                {
                    "packages": [
                        {
                            "version": [
                                "1.0.0",
                                "1.0.1",
                                "1.0.2"
                            ],
                            "package": "rp2paths"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "doc": "Extract paths from RetroPath 2.0 output\n",
            "inputs": [
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "doc": "File with name of compounds.",
                    "inputBinding": {
                        "prefix": "--cmpdnamefile"
                    },
                    "id": "#tool.cwl_2/cmpdnamefile"
                },
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "doc": "User-defined sink file, i.e. file listing compounds to consider as sink compounds.  Sink compounds should be provided by their IDs, as used in the reaction.erxn file.  If no file is provided then the sink file generated during the \"convert\" task is  used (default behavior). If a file is provided then **only** comppounds listed  in this file will be used.\n",
                    "inputBinding": {
                        "prefix": "--customsinkfile"
                    },
                    "id": "#tool.cwl_2/customsinkfile"
                },
                {
                    "type": [
                        "null",
                        "File"
                    ],
                    "doc": "Binary that enumerate the EFMs",
                    "inputBinding": {
                        "prefix": "--ebin"
                    },
                    "id": "#tool.cwl_2/ebin"
                },
                {
                    "type": "File",
                    "doc": "RetroPath file as outputed by the RetroPath2.0 workflow",
                    "inputBinding": {
                        "position": 1
                    },
                    "id": "#tool.cwl_2/infile"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "default": 150,
                    "doc": "cutoff on the maximum number of pathways",
                    "inputBinding": {
                        "prefix": "--maxpaths"
                    },
                    "id": "#tool.cwl_2/maxpaths"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "default": 10,
                    "doc": "cutoff on the maximum number of steps in a pathways",
                    "inputBinding": {
                        "prefix": "--maxsteps"
                    },
                    "id": "#tool.cwl_2/maxsteps"
                },
                {
                    "type": [
                        "null",
                        "boolean"
                    ],
                    "default": false,
                    "doc": "Use minimal depth scope, i.e. stop the scope computation as as soon an a first  minimal path linking target to sink is found (default - False).\n",
                    "inputBinding": {
                        "prefix": "--minDepth"
                    },
                    "id": "#tool.cwl_2/minDepth"
                },
                {
                    "type": [
                        "null",
                        {
                            "type": "array",
                            "items": "string"
                        }
                    ],
                    "doc": "List of compounds IDs. If specifed, paths making use of  one of these compounds as unique initial substrate will  be filtered out\n",
                    "inputBinding": {
                        "prefix": "--notPathsStartingBy"
                    },
                    "id": "#tool.cwl_2/notPathsStartingBy"
                },
                {
                    "type": [
                        "null",
                        {
                            "type": "array",
                            "items": "string"
                        }
                    ],
                    "doc": "List of compounds IDs to consider. If specified, only paths making use of  at least one of these compounds as initial substrate (first step of a pathway) are kept.\n",
                    "inputBinding": {
                        "prefix": "--onlyPathsStartingBy"
                    },
                    "id": "#tool.cwl_2/onlyPathsStartingBy"
                },
                {
                    "type": "boolean",
                    "doc": "Consider reactions in the reverse direction",
                    "inputBinding": {
                        "prefix": "--reverse"
                    },
                    "id": "#tool.cwl_2/reverse"
                },
                {
                    "type": [
                        "null",
                        "string"
                    ],
                    "doc": "Target compound internal ID. This internal ID specifies which compound  should be considered as the targeted compound. The default behavior is  to consider as the target the first compound used as a source compound  in a first iteration of a metabolic exploration. Let this value as it  is except if you know what you are doing.\n",
                    "inputBinding": {
                        "prefix": "--target"
                    },
                    "id": "#tool.cwl_2/target"
                },
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "default": 900,
                    "doc": "Timeout before killing a process (in s)",
                    "inputBinding": {
                        "prefix": "--timeout"
                    },
                    "id": "#tool.cwl_2/timeout"
                },
                {
                    "type": [
                        "null",
                        "boolean"
                    ],
                    "default": false,
                    "doc": "Unfold pathways based on equivalencie of compounds (can lead to combinatorial explosion).",
                    "inputBinding": {
                        "prefix": "--unfold_compounds"
                    },
                    "id": "#tool.cwl_2/unfold_compounds"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "outputBinding": {
                        "glob": "compounds.txt"
                    },
                    "doc": "A list of compounds\n",
                    "id": "#tool.cwl_2/compounds"
                },
                {
                    "type": "File",
                    "outputBinding": {
                        "glob": "reactions.erxn"
                    },
                    "doc": "A list of reactions  # which format?\n",
                    "id": "#tool.cwl_2/reactions"
                },
                {
                    "type": "File",
                    "outputBinding": {
                        "glob": "sinks.txt"
                    },
                    "doc": "A list of sinks\n",
                    "id": "#tool.cwl_2/sinks"
                }
            ],
            "id": "#tool.cwl_2"
        },
        {
            "class": "Workflow",
            "inputs": [
                {
                    "type": [
                        "null",
                        "int"
                    ],
                    "id": "#main/max-steps"
                },
                {
                    "type": [
                        "null",
                        "boolean"
                    ],
                    "id": "#main/reverse"
                },
                {
                    "type": "File",
                    "id": "#main/rulesfile"
                },
                {
                    "type": "File",
                    "id": "#main/sinkfile"
                },
                {
                    "type": "File",
                    "id": "#main/sourcefile"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "outputSource": "#main/rp2paths/compounds",
                    "id": "#main/compounds"
                },
                {
                    "type": "File",
                    "outputSource": "#main/rp2paths/reactions",
                    "id": "#main/reactions"
                },
                {
                    "type": "File",
                    "outputSource": "#main/rp2paths/sinks",
                    "id": "#main/sinks"
                }
            ],
            "steps": [
                {
                    "run": "#tool.cwl",
                    "in": [
                        {
                            "source": "#main/max-steps",
                            "id": "#main/rp2/input.max-steps"
                        },
                        {
                            "source": "#main/rulesfile",
                            "id": "#main/rp2/input.rulesfile"
                        },
                        {
                            "source": "#main/sinkfile",
                            "id": "#main/rp2/input.sinkfile"
                        },
                        {
                            "source": "#main/sourcefile",
                            "id": "#main/rp2/input.sourcefile"
                        }
                    ],
                    "out": [
                        "#main/rp2/solutionfile"
                    ],
                    "id": "#main/rp2"
                },
                {
                    "run": "#tool.cwl_2",
                    "in": [
                        {
                            "source": "#main/rp2/solutionfile",
                            "id": "#main/rp2paths/infile"
                        },
                        {
                            "source": "#main/reverse",
                            "id": "#main/rp2paths/reverse"
                        }
                    ],
                    "out": [
                        "#main/rp2paths/compounds",
                        "#main/rp2paths/reactions",
                        "#main/rp2paths/sinks"
                    ],
                    "id": "#main/rp2paths"
                }
            ],
            "id": "#main"
        }
    ],
    "cwlVersion": "v1.0"
}