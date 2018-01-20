# Problem

Why is it still so hard to setup and operate services? Complexity. Everything is different in weird ways so we customize.

How do we simplify? Reduce differences between apps.

Why can't we have a single type of app that is deployed uniformly everywhere and operated exactly the same? Same reason why most apps can't run in Heroku: their contract is too simplistic and real apps need a lot more stuff.

# App Types

We are creating a method that makes service deployments 1000x easier to operate at scale and helps with all kinds of cloud-based applications, from apps to databases. It's Heroku for everything else.

Heroku is amazing because it has simple contracts. But it's limited. We need a platform that supports different types of contracts so different *classes* of applications can be built and run at scale.

# Requirements of a YourBase app

Everything is like a replaceable electronic component: it is allowed to run any code it wants, but:

- inputs and outputs are clearly defined. Only managed interfaces are allowed. App is sandboxed (perhaps not in production to avoid performance issues).
- standard control surfaces allow for management and analysis at very large scale
- runtime configuration is uniform across a deployment type (like in helm chart). but only a small number of deployment types are allowed: modular "types of apps"
- the app must provide telemetry for the platform to understand its behavior and tune things accordingly

# Cost model

If cost of management is:

O(apps) =
O(deployments * types of Apps) 

currently both numbers are very high which leads to # of devOps across the globe doing repetitive work.

Effect of above technology:

- marginal cost of new deployments is close to zero
- app cost creation is O(1) because even though creating a new type of app may be occasionally necessary, that cost is amortized because it won't happen again for this type of app.

# How the app would look like

main.go
BUILD.base with the code
app.yaml with metadata. Very limited surface, but very expressive:

- GoHttpServer => type of server  (this needs to be composable, Go + HTTPServer + gRPCServer to support things like cockroachdb that has all of that)
- Replicas => 40
- Logging Enabled
- Container image

- Ports, ingress configs, can be complicated. See helm charts.

How do we differentiate from helm charts? Runtime behavior is uniform, monitored and there's feedback.

All apps would have a *template* config similar to cockroach db's helm chart. But the developer-facing configs would be trivial.

If we can run a CockroachDB cluster with just a few lines of user configs, that's a sign the model of scaling by App Types works.

# Feedback loop

The app isn't just fire-and-forget. It has telemetry to ensure it's behaving as appropriate. All telemetry is standardized, so any person can go and debug an app they don't know much about.

This means platform owners can run stuff for zillions of people at the same time. Uber for cloud.

# Example composable attributes of apps

- UsesDockerRegistry
	- needs a serviceaccount (GCP specific? seems like a k8s concept)
	- needs to patch the "imagePullSecrets" into the serviceaccount using kubectl
- ...

# References

- software components http://blogs.windriver.com/koning/2006/09/components.html
