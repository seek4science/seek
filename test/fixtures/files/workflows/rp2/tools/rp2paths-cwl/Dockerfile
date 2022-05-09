FROM scratch as cwl
COPY /tools /usr/share/cwl/rp2paths 
LABEL org.w3id.cwl.tool /usr/share/cwl/rp2paths/rp2paths.cwl
 
FROM conda/miniconda3
# Check for new versions from 
# https://github.com/brsynth/rp2paths/releases
ENV RP2PATHS_VERSION 1.0.2
ENV RP2PATHS_URL https://github.com/brsynth/rp2paths/archive/v${RP2PATHS_VERSION}.tar.gz
# NOTE: Update sha256sum for each release
ENV RP2PATHS_SHA256 3813460dea8bb02df48e1f1dfb60751983297520f09cdfcc62aceda316400e66

# Although graphviz is also in conda, it depends on X11 libraries in /usr/lib
# which this Docker image does not have.
# We'll sacrifize space for a duplicate install to get all the dependencies
# Tip: openjdk-8-jre needed to launch efm
RUN apt-get --quiet update && \
    # debian security updates as conda/miniconda3:latest is seldom updated
    apt-get --quiet --yes dist-upgrade && \
    apt-get --quiet --yes install \
        curl \
        graphviz \
        openjdk-8-jre

## Install rest of dependencies as Conda packages
# Update conda base install in case base Docker image is outdated
RUN conda update --quiet --yes conda && conda update --all --yes

# Install rdkit first as it has loads of dependencies
# Check for new versions at
# https://anaconda.org/rdkit/rdkit/labels
RUN conda install --quiet --yes --channel rdkit rdkit=2018.03.4.0
# TODO: are any of these already included from rdkit above?
RUN conda install --quiet --yes python-graphviz pydotplus lxml 
# FIXME: Is it pip's image or conda's scikit-image?
#RUN pip install -y image
#conda install scikit-image


# Download and "install" rp2paths release
WORKDIR /tmp
RUN echo "$RP2PATHS_SHA256  rp2paths.tar.gz" > rp2paths.tar.gz.sha256
RUN cat rp2paths.tar.gz.sha256
RUN echo Downloading $RP2PATHS_URL
RUN curl -v -L -o rp2paths.tar.gz $RP2PATHS_URL && sha256sum rp2paths.tar.gz && sha256sum -c rp2paths.tar.gz.sha256
RUN mkdir src && cd src && tar xfv ../rp2paths.tar.gz && mv */* ./
RUN mv src /opt/rp2paths
# Patch in #!/ shebang if missing
RUN grep -q '^#!/' RP2paths.py || sed -i '1i #!/usr/bin/env python3' /opt/rp2paths/RP2paths.py
# Make it available on PATH
RUN ln -s /opt/rp2paths/RP2paths.py /usr/local/bin/RP2paths.py
RUN ln -s /opt/rp2paths/RP2paths.py /usr/local/bin/rp2paths
# Verify the install 
RUN rp2paths --help
# Verify full execution (Note: We're NOT in /opt/rp2paths folder)
RUN rp2paths all /opt/rp2paths/examples/violacein/rp2-results.csv --outdir /tmp/1 && ls /tmp/1 && rm -rf /tmp/1

COPY --from=cwl /usr/share/cwl/rp2paths /usr/share/cwl/rp2paths
LABEL org.w3id.cwl.tool /usr/share/cwl/rp2paths/rp2paths.cwl

# Default command is to run on /data/rp2-results.csv
# and output to /data/pathways/
# /data is a VOLUME so these can more easily be accessed
# outside the Docker container
RUN mkdir /data
VOLUME /data
WORKDIR /data
CMD ["/usr/local/bin/rp2paths", "all", "rp2-results.csv", "--outdir", "pathways/"]

