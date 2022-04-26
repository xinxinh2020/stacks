package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/scm/github"
)

dagger.#Plan & {
	client: {
		filesystem: {
			code: read: contents: dagger.#FS
			"./output.yaml": write: {
				// Convert a CUE value into a YAML formatted string
				contents: actions.up.outputYaml.output
			}
		}
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:      string
			APP_NAME:        string
			ORGANIZATION:    string
			GITHUB_TOKEN:    dagger.#Secret
			REPO_VISIBILITY: "public" | "private"
		}
	}

	actions: {
		applicationName: client.env.APP_NAME
		accessToken:     client.env.GITHUB_TOKEN
		organization:    client.env.ORGANIZATION
		sourceCodeDir:   client.filesystem.code.read.contents

		up: {
			initRepos: {
				initBackendRepo: github.#ManageRepo & {
					sourceCodePath:    "go-gin"
					suffix:            ""
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					"sourceCodeDir":   sourceCodeDir
					repoVisibility:    client.env.REPO_VISIBILITY
					kubeconfig:        client.commands.kubeconfig.stdout
					operationType:     "init"
				}
			}
			outputYaml: #OutputStruct & {
				repository: {
					backend:  initRepos.initBackendRepo.url
				}
			}
		}

		down: {
			deleteRepos: {
				deleteBackendRepo: github.#ManageRepo & {
					sourceCodePath:    "go-gin"
					suffix:            ""
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					"sourceCodeDir":   sourceCodeDir
					repoVisibility:    client.env.REPO_VISIBILITY
					kubeconfig:        client.commands.kubeconfig.stdout
					operationType:     "delete"
				}
			}
		}
	}
}
