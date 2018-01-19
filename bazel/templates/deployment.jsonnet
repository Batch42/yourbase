local k = import "external/com_github_ksonnet_lib/ksonnet.beta.2/k.libsonnet";

// Specify the import objects that we need
local container = k.extensions.v1beta1.deployment.mixin.spec.template.spec.containersType;
local deployment = k.extensions.v1beta1.deployment;
local ingress = k.extensions.v1beta1.ingress;
local service = k.core.v1.service;

local containerPort = container.portsType;
local servicePort = k.core.v1.service.mixin.spec.portsType;


local appPort = 8080;
local svcPort = 80;

local podLabels = {app: std.extVar("mc_app")};

local appContainer =
  container.new(std.extVar("mc_app"), std.extVar("mc_image")) +
  container.ports(containerPort.containerPort(appPort)) +
  container.imagePullPolicy("Always"); # TODO: use a pinned digest instead.

# TODO: Move back to 2+ replicas once we can read CI bot output more reliably.
local appDeployment =
  deployment.new(std.extVar("mc_app") + "-deployment", 1, appContainer, podLabels);

local appService = service
  .new(
    std.extVar("mc_svc"),
    podLabels,
    null) +
  {"spec": {
    "selector": podLabels,
    "type": "LoadBalancer",
    "ports" : [{
      "protocol": "TCP",
      "port": svcPort,
      "targetPort": appPort,
    }]
  },
};

// FIXME: we don't need an ingress for each service.
// REMOVED
local appIngress = ingress.new() + {
  "metadata": {
    "name": std.extVar("mc_ingress"),
    "annotations": {
      "kubernetes.io/ingress.global-static-ip-name": "mc-ingress"
    }
  },
  "spec": {
    "backend": {
      "serviceName": std.extVar("mc_svc"),
      "servicePort": svcPort
    }
  }
};

k.core.v1.list.new([appDeployment, appService])
