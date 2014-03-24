#!/bin/sh

basedir=$(dirname $0)
privdir=${basedir}/priv
hdrdir=${basedir}/include/internal

known_nss_src=exmpp_known_nss.in
known_elems_src=exmpp_known_elems.in
known_attrs_src=exmpp_known_attrs.in

( ${privdir}/make-specs-list; cat ${privdir}/occi-schemas.in ) \
    | ${privdir}/extract-known-from-specs \
		${hdrdir}/${known_nss_src} \
		${hdrdir}/${known_elems_src} \
		${hdrdir}/${known_attrs_src}
