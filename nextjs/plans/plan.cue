package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/scm/github"
	"github.com/h8r-dev/stacks/cuelib/deploy/helm"
	"github.com/h8r-dev/stacks/cuelib/network/ingress"
	githubAction "github.com/h8r-dev/stacks/cuelib/ci/github"
	"github.com/h8r-dev/stacks/cuelib/framework/react/next"
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
		applicationInstallNamespace: client.env.APP_NAME + "-" + appInstallNamespace

		up: {
			getIngressEndPoint: ingress.#GetIngressEndpoint & {
				kubeconfig: client.commands.kubeconfig.stdout
			}

			// get ingress version
			getIngressVersion: ingress.#GetIngressVersion & {
				kubeconfig: client.commands.kubeconfig.stdout
			}

			initRepos: {
				frontend: next.#Create & {
					name:       applicationName
					typescript: true
				}

				// add github action
				addGithubAction: githubAction.#Create & {
					input: frontend.output
					path:  applicationName + "/.github/workflows"
				}

				initFrontendRepo: github.#ManageRepo & {
					suffix:            "-front"
					sourceCodePath:    "root/" + applicationName
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					sourceCodeDir:     addGithubAction.output.rootfs
					repoVisibility:    client.env.REPO_VISIBILITY
					kubeconfig:        client.commands.kubeconfig.stdout
					operationType:     "init"
				}

				initHelmRepo: github.#ManageRepo & {
					suffix:            "-deploy"
					sourceCodePath:    "helm"
					isHelmChart:       "true"
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					"sourceCodeDir":   sourceCodeDir
					repoVisibility:    client.env.REPO_VISIBILITY
					kubeconfig:        client.commands.kubeconfig.stdout
					operationType:     "init"
				}
			}

			installIngress: helm.#Chart & {
				name:         "ingress-nginx"
				repository:   "https://kubernetes.github.io/ingress-nginx"
				chart:        "ingress-nginx"
				namespace:    "ingress-nginx"
				action:       "installOrUpgrade"
				kubeconfig:   client.commands.kubeconfig.stdout
				values:       ingressNginxSetting
				wait:         true
				chartVersion: "4.0.19"
			}

			// install argocd
			installArgoCD: argocd.#Install & {
				kubeconfig:     client.commands.kubeconfig.stdout
				namespace:      argoCDNamespace
				url:            "https://raw.githubusercontent.com/argoproj/argo-cd/v2.3.3/manifests/install.yaml"
				"uri":          uri.output
				ingressVersion: getIngressVersion.content
				domain:         argocdDomain
				host:           getIngressEndPoint.content
				waitFor:        installIngress.success
			}

			// Create application on argocd
			createApp: argocd.#App & {
				waitFor: installArgoCD.success
				config:  argocd.#Config & {
					version: "v2.3.1"
					server:  argocdDomain
					basicAuth: {
						username: argoCDDefaultUsername
						password: installArgoCD.content
					}
				}
				name:               client.env.APP_NAME
				repo:               initRepos.initHelmRepo.url
				namespace:          applicationInstallNamespace
				path:               "."
				helmSet:            "ingress.hosts[0].paths[0].servicePort=80,ingress.hosts[0].paths[1].servicePort=8000,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[1].path=/api,ingress.hosts[0].host=" + appDomain + ",ingress.hosts[0].paths[0].serviceName=" + client.env.APP_NAME + "-front,ingress.hosts[0].paths[1].serviceName=" + client.env.APP_NAME
				githubToken:        client.env.GITHUB_TOKEN
				githubOrganization: client.env.ORGANIZATION
			}

			initApplication: app: h8r.#CreateH8rIngress & {
				name:   uri.output + "-gin-vue"
				host:   getIngressEndPoint.content
				domain: applicationInstallNamespace + "." + appDomain
				port:   "80"
			}

			outputYaml: #OutputStruct & {
				application: {
					domain:  applicationInstallNamespace + "." + appDomain
					ingress: getIngressEndPoint.content
				}
				repository: {
					frontend: initRepos.initFrontendRepo.url
					deploy:   initRepos.initHelmRepo.url
				}
				argocd: {
					domain:   argocdDomain
					username: argoCDDefaultUsername
					password: installArgoCD.content
				}
			}
		}

		down: {
			deleteRepos: {
				deleteFrontendRepo: github.#ManageRepo & {
					suffix:            "-front"
					sourceCodePath:    "frontend"
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					"sourceCodeDir":   sourceCodeDir
					repoVisibility:    client.env.REPO_VISIBILITY
					kubeconfig:        client.commands.kubeconfig.stdout
					operationType:     "delete"
				}

				deleteHelmRepo: github.#ManageRepo & {
					suffix:            "-deploy"
					sourceCodePath:    "helm"
					isHelmChart:       "true"
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
