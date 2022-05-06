#!/usr/bin/env bash
set -e

EXPECTED_FILES="compounds.txt efm.err efm.log out_comp out_discarded out_efm out_full_react out_graph1.dot out_graph1.svg out_info out_mat out_paths.csv out_react out_rever reactions.erxn sinks.txt"

for ex in examples/*; do
  pushd $ex
    echo "Testing rp2paths all $ex/rp2-results.csv"
    # Ensure always new output directory
    out=`mktemp -d`
    docker run -v `pwd`:/data -v $out:/data/pathways ibisba/rp2paths
    for f in $EXPECTED_FILES; do
        test -f $out/$f || ( echo "Can't find $f " >&2 ; false )
        # TODO: Check file is non-empty
    done
    # TODO: Check img/* exists
  popd
done

for i in $(find tools workflows -name "*.cwl"); do
 echo "Validating workflow: ${i}"
 cwltool --validate ${i}
done
for j in $(find workflows -name "*.-job.yaml"); do
 echo "Running workflow job: ${j}"
 cwltool --verbose --default-container debian --outdir `mktemp -d` ${j}
done
