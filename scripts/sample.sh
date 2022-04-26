#! /usr/bin/env bash

set -e

STACK_ROOT_DIR=$PWD
SAMPLE_STACK_DIR=$STACK_ROOT_DIR/sample

if [ ! -d $SAMPLE_STACK_DIR ]; then
  echo "You should run the sample.sh script under stacks root dir"
  exit 1
fi

cd $SAMPLE_STACK_DIR

# Install dependencies
echo "Install dependencies"
hof mod vendor cue && dagger project update

echo "Run sample stack"
hln up -i
