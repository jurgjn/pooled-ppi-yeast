#!/bin/sh
apt-get update --quiet
apt-get install --yes --quiet skopeo umoci
rm -rf /data
mkdir -p /data
skopeo copy docker://jurgjn/pooled-ppi-yeast:v26.1 oci:/tmp/_oci:v26.1
umoci unpack --image /tmp/_oci /tmp/_unpack
mv /tmp/_unpack/rootfs/data/* /data
