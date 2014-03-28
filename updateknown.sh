#!/bin/sh
#
# Update the list of XMPP specs from xmpp.org website.
#
# Copyright (c) 2014 Jean Parpaillon
# Author(s): Jean Parpaillon <jean.parpaillon@free.fr>
#
basedir=$(dirname $0)
privdir=${basedir}/priv
hdrdir=${basedir}/include/internal

known_nss_src=exmpp_known_nss.in
known_elems_src=exmpp_known_elems.in
known_attrs_src=exmpp_known_attrs.in

${privdir}/make-specs-list \
    | ${privdir}/extract-known-from-specs \
		${hdrdir}/${known_nss_src} \
		${hdrdir}/${known_elems_src} \
		${hdrdir}/${known_attrs_src}
