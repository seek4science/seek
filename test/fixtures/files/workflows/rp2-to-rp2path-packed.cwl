{
    "cwlVersion": "v1.0",
    "inputs": [
        {
            "id": "#main/input.cofsfile",
            "inputBinding": {
                "separate": false,
                "prefix": "input.cofsfile="
            },
            "type": [
                "null",
                "File"
            ]
        },
        {
            "id": "#main/input.dmax",
            "inputBinding": {
                "separate": false,
                "prefix": "input.dmax="
            },
            "type": [
                "null",
                "int"
            ]
        },
        {
            "id": "#main/input.dmin",
            "inputBinding": {
                "separate": false,
                "prefix": "input.dmin="
            },
            "type": [
                "null",
                "int"
            ]
        },
        {
            "id": "#main/input.max-steps",
            "inputBinding": {
                "separate": false,
                "prefix": "input.max-steps="
            },
            "type": [
                "null",
                "int"
            ]
        },
        {
            "id": "#main/input.mwmax-cof",
            "inputBinding": {
                "separate": false,
                "prefix": "input.mwmax-cof="
            },
            "type": [
                "null",
                "int"
            ]
        },
        {
            "id": "#main/input.mwmax-source",
            "inputBinding": {
                "separate": false,
                "prefix": "input.mwmax-source="
            },
            "type": [
                "null",
                "int"
            ]
        },
        {
            "id": "#main/input.rulesfile",
            "inputBinding": {
                "separate": false,
                "prefix": "input.rulesfile="
            },
            "type": "File"
        },
        {
            "id": "#main/input.sinkfile",
            "inputBinding": {
                "separate": false,
                "prefix": "input.sinkfile="
            },
            "type": [
                "null",
                "File"
            ]
        },
        {
            "id": "#main/input.sourcefile",
            "inputBinding": {
                "separate": false,
                "prefix": "input.sourcefile="
            },
            "type": "File"
        },
        {
            "id": "#main/input.std_mode",
            "inputBinding": {
                "separate": false,
                "prefix": "input.std_mode="
            },
            "type": [
                "null",
                "string"
            ]
        },
        {
            "id": "#main/input.stereo_mode",
            "inputBinding": {
                "separate": false,
                "prefix": "input.stereo_mode="
            },
            "type": [
                "null",
                "string"
            ]
        },
        {
            "id": "#main/input.topx",
            "inputBinding": {
                "separate": false,
                "prefix": "input.topx="
            },
            "type": [
                "null",
                "int"
            ]
        }
    ],
    "class": "CommandLineTool",
    "baseCommand": null,
    "stdout": "output.txt",
    "id": "#main",
    "arguments": [
        "output.dir=$(runtime.outdir)"
    ],
    "outputs": [
        {
            "id": "#main/solutionfile",
            "outputBinding": {
                "glob": "results.csv"
            },
            "type": "File"
        },
        {
            "id": "#main/sourceinsinkfile",
            "outputBinding": {
                "glob": "source-in-sink.csv"
            },
            "type": [
                "null",
                "File"
            ]
        },
        {
            "id": "#main/stdout",
            "outputBinding": {
                "glob": "output.txt"
            },
            "type": "File"
        }
    ],
    "hints": [
        {
            "class": "DockerRequirement",
            "dockerPull": "ibisba/retropath2:latest"
        }
    ]
}