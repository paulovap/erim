#!/bin/bash -e
#
# Add a custom schema to known XML attrs/elems/nss
#
# Copyright (c) 2014 Jean Parpaillon
# Author(s): Jean Parpaillon <jean.parpaillon@free.fr>
#
basedir=$(dirname $0)
privdir=${basedir}/priv
hdrdir=${basedir}/include/internal

known_nss_src=${hdrdir}/exmpp_known_nss.in
known_elems_src=${hdrdir}/exmpp_known_elems.in
known_attrs_src=${hdrdir}/exmpp_known_attrs.in

usage() {
    echo "Usage: $0 /path/to/schema"
}

if [ $# -lt 1 ]; then
    usage
    exit 0
fi

if [ ! -e $1 ]; then
    echo "Invalid schema"
    exit 1
fi

xsltproc --stringparam src "$(basename $1)" ${privdir}/extract_nss.xsl $1 >> ${known_nss_src}
xsltproc --stringparam src "$(basename $1)" ${privdir}/extract_elems.xsl $1 >> ${known_elems_src}
xsltproc --stringparam src "$(basename $1)" ${privdir}/extract_attrs.xsl $1 >> ${known_attrs_src}
