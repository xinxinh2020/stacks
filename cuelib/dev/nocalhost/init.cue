package nocalhost

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/scm/github"
)

#InitData: {
	url:                string | *"nocalhost-web.nocalhost"
	githubAccessToken:  dagger.#Secret
	githubOrganization: string
	kubeconfig:         string | dagger.#Secret
	appName:            string
	appGitURL:          string
	waitFor:            bool

	getToken: #GetToken & {
		"url":     url
		"waitFor": waitFor
	}

	githubOrganizationMembers: github.#GetOrganizationMembers & {
		accessToken:  githubAccessToken
		organization: githubOrganization
	}

	createTeam: #CreateTeam & {
		token:   getToken.output
		members: githubOrganizationMembers.output
		"url":   url
	}

	createCluster: #CreateCluster & {
		token:        getToken.output
		"url":        url
		"kubeconfig": kubeconfig
	}

	createApplication: #CreateApplication & {
		token:       getToken.output
		"url":       url
		"appName":   appName
		"appGitURL": appGitURL
	}

	createDevSpace: #CreateDevSpace & {
		token:   getToken.output
		"url":   url
		waitFor: createTeam.success & createCluster.success
	}

	nsOutput: createDevSpace.nsOutput
}
