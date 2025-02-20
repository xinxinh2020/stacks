package nocalhost

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/cuelib/dev/nocalhost"
	"github.com/h8r-dev/stacks/cuelib/deploy/kubectl"
)

#Instance: {
	input: #Input

	_getGitURL: bash.#Run & {
		"input": input.image
		script: contents: #"""
			deployRepoPath=$(cat /h8r/application)
			cd /scaffold/$deployRepoPath
			repoURL=$(git config --get remote.origin.url | tr -d '\n')
			printf  "$repoURL" > /result
			"""#
		export: files: "/result": string
	}

	do: {
		init: nocalhost.#InitData & {
			githubAccessToken:  input.githubAccessToken
			githubOrganization: input.githubOrganization
			kubeconfig:         input.kubeconfig
			appName:            input.appName
			appGitURL:          _getGitURL.export.files."/result"
			waitFor:            _getGitURL.success
		}
		createImagePullSecretForDevNs: kubectl.#CreateImagePullSecret & {
			kubeconfig: input.kubeconfig
			username:   input.githubOrganization
			password:   input.githubAccessToken
			namespace:  init.nsOutput
		}
	}

	output: #Output & {
		image: input.image
	}
}
