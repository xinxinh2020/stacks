package main

import (
	"github.com/h8r-dev/stacks/cuelib/utils/random"
)

// random uri
uri: random.#String

// Application install namespace
appInstallNamespace: "production"

// App domain prefix
appDomain: uri.output + ".go-gin.h8r.app"

// Infra domain
infraDomain: ".stack.h8r.io"

// ArgoCD URL
argocdDomain: uri.output + ".argocd" + infraDomain

// ArgoCD namespace
argoCDNamespace:       "argocd"
argoCDDefaultUsername: "admin"

ingressNginxNamespace: "ingress-nginx"

ingressNginxSetting: #"""
	controller:
	  service:
	    type: LoadBalancer
	  metrics:
	    enabled: true
	  podAnnotations:
	    prometheus.io/scrape: "true"
	    prometheus.io/port: "10254"
	"""#