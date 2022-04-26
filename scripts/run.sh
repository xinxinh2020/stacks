#! /usr/bin/env bash

set -e

ALL_STACKS_ROOT_DIR=$PWD
STACK_DIR=$ALL_STACKS_ROOT_DIR/$1

if [ ! -d $STACK_DIR ]; then
  echo "$STACK_DIR is not found or You should run the sample.sh script under stacks root dir"
  exit 1
fi

cd $STACK_DIR

# Install dependencies
echo "Install dependencies"
hof mod vendor cue && dagger project update

echo "Run stack: $1"
hln up -i
