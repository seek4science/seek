# RP2paths -- RetroPath2.0 to pathways

[![Build Status](https://travis-ci.org/IBISBA/rp2paths-cwl.svg?branch=master)](https://travis-ci.org/IBISBA/rp2paths-cwl)
[![](https://images.microbadger.com/badges/version/ibisba/rp2paths.svg)](https://hub.docker.com/r/ibisba/rp2paths "ibisba/rp2paths")
[![](https://images.microbadger.com/badges/image/ibisba/rp2paths.svg)](https://microbadger.com/images/ibisba/rp2paths "Get your own image badge on microbadger.com")

* Docker image: [ibisba/rp2paths](https://hub.docker.com/r/ibisba/rp2paths/)
* Base images: [conda/miniconda3/](https://hub.docker.com/r/conda/miniconda3/)  [debian](https://hub.docker.com/r/_/debian/) 
* Source: [Dockerfile](https://github.com/IBISBA/rp2paths-cwl/blob/master/Dockerfile), [rp2paths](https://github.com/brsynth/rp2paths)
* License: [MIT License](LICENSE.txt) (dependencies other open source licenses)

RP2paths extracts the set of pathways that lies in a metabolic space file as outputted from the [RetroPath2.0 workflow](https://www.myexperiment.org/workflows/4987)

This is the [Docker](https://www.docker.com/) image and (eventually) [CWL](https://www.commonwl.org/) wrapping of [rp2paths](https://github.com/brsynth/rp2paths) from Jean-Loup Faulon's group & INRA. This wrapper is maintained by [IBISBA 1.0](https://www.ibisba.eu/), a project with funding from the European Union's _Horizon 2020_ research and innovation programme under grant agreement n° [730976](http://cordis.europa.eu/projects/730976)


## Quick start

The command line tool is accessible as `rp2paths` within the Docker image [ibisba/rp2paths](https://hub.docker.com/r/ibisba/rp2paths/) on Docker Hub.

Given a scope file `rp2-results.csv` in the current directory, as produced by [RetroPath2.0](https://www.myexperiment.org/workflows/4987), a typical command line for extracting the pathways from the results is:

```
docker run -v `pwd`:/data ibisba/rp2paths 
```

Note that the above maps the current directory `pwd` to `/data` inside the Docker container. 

The rp2paths extracts will afterwards be in the `pathways/` folder:

```
~/examples/carotene$ ls pathways/
compounds.txt  out_discarded   out_graph2.dot  out_react
efm.err        out_efm         out_graph2.svg  out_rever
efm.log        out_full_react  out_info        reactions.erxn
img            out_graph1.dot  out_mat         sinks.txt
out_comp       out_graph1.svg  out_paths.csv

~/examples/carotene$ ls pathways/img
CMPD_0000000001.svg  CMPD_0000000008.svg  TARGET_0000000001.svg
CMPD_0000000003.svg  CMPD_0000000009.svg
CMPD_0000000004.svg  MNXM83.svg
```

The below example customize the rp2paths parameters, here providing `/home/alice/examples/carotene` as the data folder. Note that when customizing you have to provide the paths to `rp2-results.csv` and the output directory relative to `/data`:

```
docker run -v /home/alice/examples/carotene:/data ibisba/rp2paths ibisba/rp2paths rp2paths all rp2-results.csv --outdir pathways
```

where:
- `all` specify that all the tasks needed for retreiving pathways will be executed at once.
- `rp2-results.csv` is the metabolic space outputted by the RetroPath2.0 workflow.
- `--outdir pathways` specify the directory in which all files will be outputted (here `/data/pathways` in the container, aka `/home/alice/examples/carotene/pathways` on the host).



In the output folder (here `pathways`), the complete set of pathways enumerated will be written in the `out_paths.csv` file. In addition, for each pathway there will be a .dot file (.dot representation of the graph) and a .svg file (.svg depiction of the pathway).

Additional options are described in the embedded help
```
docker run ibisba/rp2paths rp2paths --help
docker run ibisba/rp2paths rp2paths all --help
```

## Contributing

To build the docker image yourself, use

```
docker build -t ibisba/rp2paths .
```

You may test the Docker image locally, replicating what is run automatically by [Travis CI](https://travis-ci.org/IBISBA/rp2paths-cwl):

```
./test.sh
```

To contribute fixes to this Docker/CWL wrapping, raise a [issue](https://github.com/IBISBA/rp2paths-cwl/issues) or [pull request](https://github.com/IBISBA/rp2paths-cwl/pulls)

For improvements on [rp2paths](https://github.com/brsynth/rp2paths) itself you may raise an [issues](https://github.com/brsynth/rp2paths/issues) or [pull request](https://github.com/brsynth/rp2paths/pulls)

Contributions are assumed to be covered by the [MIT license](LICENSE.txt).


### How to cite RP2paths?
Please cite:

Delépine B, Duigou T, Carbonell P, Faulon JL. RetroPath2.0: A retrosynthesis workflow for metabolic engineers. Metabolic Engineering, 45: 158-170, 2018. DOI: https://doi.org/10.1016/j.ymben.2017.12.002

### Licence
RP2paths, the `Dockerfile`, examples and cwl tool descriptions are released under the MIT licence. See the [LICENCE.txt](LICENSE.txt) file for details.

The Docker image contains software dependencies under other open source licenses. Notably:

* [debian](https://hub.docker.com/r/_/debian/): [GNU GPL and others](https://www.debian.org/legal/licenses/)
* [conda/miniconda3](https://hub.docker.com/r/conda/miniconda3/): [BSD 3-clause and others](https://conda.io/docs/license.html)
* [rdkit](https://anaconda.org/rdkit/rdkit): [BSD 3-clause](https://github.com/rdkit/rdkit/blob/master/license.txt)
* [openjdk-8](https://packages.debian.org/stretch/openjdk-8-jre): [GNU GPL 2 with classpath exception](http://openjdk.java.net/legal/gplv2+ce.html)
* [python3](https://anaconda.org/anaconda/python): [PSF and others](https://docs.python.org/3/license.html)