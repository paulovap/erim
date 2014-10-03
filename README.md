# erim

erim is an erlang application which provides the modules to ease the
development of an XMPP/Jabber server or client.

It is a fork of exmpp from ProcessOne.

## Table of contents

1. Requirements
2. Build and install
3. Building examples
4. Why a fork ?
5. Roadmap

## 1. Requirements

* Erlang/OTP (REQUIRED)
  A full Erlang environment is recommended but only ERTS and erl_interface are required.
  * Minimum version: R12B-5
* rebar: erim uses rebar for compilation and dependancies management.
* lager: is used for logging
* C compiler (REQUIRED)
  erim contains erlang port drivers which are written in C.
  Tested C compilers include:
  * GNU Compiler Collection (gcc)
* XML parsing library (REQUIRED)
  Tested libraries are:
  * Expat: recommended. Tested: 2.0.1
  * LibXML2: only experimental support.
* OpenSSL (optional)
  It's the only TLS engine supported for now.
  * Tested version: 0.9.8e
* zlib (optional)
  It's the only compression engine supported for now.
  * Tested version: 1.2.3
* eunit (optional)
  To be able to use the testsuite, this Erlang application is required.
  * Tested version: 2.0

## 2. Build and install

erim uses rebar:

  $ rebar get-deps
  $ rebar compile

## 3. Building examples

Examples are built when building erim.

## 4. Why a fork ?

erim is based on the excellent exmpp from Process One. exmpp is
relying on a lot of non-erlang tools like:
* autotools
* javascript and/or awk for file generation

We've proposed several patches to uses tools more adapted for
inclusion in modern erlang projects like:
* rebar: compilation and depandancy management
* escript for replacing awk/js scripts

As we have not received any feedback from these patches, we've decided
to maintain our own branch then, to limit confusion, rename it. We'll
be pleased to contribute to a common branch as soon as we'll havea
contact from original exmpp developers.

## 5. Roadmap

The global objective is to improve portability of exmpp by limiting
the depandancies to non-erlang code.

It includes using pure erlang XML parser (xmerl or custom one, based
on iolist and binaries for performance)
