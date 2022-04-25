package main

import (
	"universe.dagger.io/bash"
	"encoding/yaml"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
)

// output cue struct
#OutputStruct: {
	application: {
		// application domain
		domain: string
		// ingress endpoint
		ingress: string
	}

	// git repository
	repository: {
		frontend: string
		deploy: string
	}

	argocd: {
		domain:   string
		username: string
		password: string
	}

	outputStruct: {
		"application": {
			domain:  application.domain
			ingress: application.ingress
		}
		"repository": {
			frontend: repository.frontend
			deploy:   repository.deploy
		}
		infra: {
			[
				{
					type:     "argoCD"
					url:      argocd.domain
					username: argocd.username
					password: argocd.password
				}
			]
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
