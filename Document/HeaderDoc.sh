#! /bin/bash

# current path
PWD_PATH=`pwd`
# document path
DOC_PATH="${PWD_PATH}/HeaderDoc/"
# source path
SRC_PATH="${PWD_PATH}/../FWFramework/"

# clear document
rm -rf "${DOC_PATH}"
mkdir -p "${DOC_PATH}"

# generate headerdoc .h
find "${SRC_PATH}" -name \*.h -print | xargs headerdoc2html -o "${DOC_PATH}"
# generate headerdoc *
# headerdoc2html -o "${DOC_PATH}" "${SRC_PATH}"

# gather headerdoc
gatherheaderdoc "${DOC_PATH}"

# open document path
open "${DOC_PATH}"
