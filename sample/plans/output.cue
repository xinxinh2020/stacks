package main

import (
	"universe.dagger.io/bash"
	"encoding/yaml"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
)

// output cue struct
#OutputStruct: {
	// git repository
	repository: {
		backend:  string
	}
	outputStruct: {
		"repository": {
			backend:  repository.backend
		}
	}

	outputYaml: yaml.Marshal(outputStruct)

	_inputImage: base.#Kubectl

	run: bash.#Run & {
		input: _inputImage.output
		script: contents: #"""
			    printf '\#(outputYaml)' > /output.yaml
			"""#
		export: files: "/output.yaml": string
	}

	output: run.export.files."/output.yaml"
}
