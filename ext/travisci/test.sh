#!/bin/bash

set -x
set -e

LEIN="${1:-lein2}"

# get_dep_version
# :arg1 is the dependency project whose version we want to grab from project.clj
get_dep_version() {
	local REGEX="puppetlabs\/${1:?} "
	$LEIN pprint :dependencies | grep "$REGEX" | cut -d\" -f2
}

rm -rf checkouts && mkdir checkouts

# Clone each dependency locally into the ./checkouts directory so we can install
# from source into the local ~/.m2/repository
pushd checkouts

git clone https://github.com/puppetlabs/puppetdb

# Try to checkout to the "release" tag in puppetdb corresponding to
# the dependency version. If we can't find it, just use the master branch.
depversion="$(get_dep_version 'puppetdb')"
pushd 'puppetdb'
if [ -n "$(git tag -l | grep $depversion | awk '{print $2;}')" ]
then
    git checkout $depversion
fi
$LEIN install
popd

popd

ulimit -u 4096
psql -c 'create database puppetdbtest;' -U postgres
PUPPETDB_DBTYPE=postgres \
PUPPETDB_DBUSER=postgres \
PUPPETDB_DBSUBNAME=//127.0.0.1:5432/puppetdbtest \
PUPPETDB_DBPASSWORD= \
$LEIN test
