load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("@io_bazel_rules_docker//go:image.bzl", "go_image", )
load("@io_bazel_rules_docker//container:container.bzl", "container_push")
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")
load(
    "@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl",
    "jsonnet_library",
    "jsonnet_to_json",
)

def go_http_server(name, library=None, environment_access=None, app_config=None,
  registry = "gcr.io", args=None, files=None, base=None, enable_conformance_testing=True):
  """Create a deployable Go server with bells and whistles.

  Arguments:
    - name: it must be a *globally unique name* in the cloud namespace.
    - files: additional files to add to the server
    - base: alternative base container image. Useful if you need a richer
      system including a shell.
    - enable_conformance_testing: if enabled, run conformance tests again this
      server. Test currently available:
      - HTTP client test: assumes it runs on port 8080 and responds with 200
	for requests to /.

  Output:
    ..._image: container image
    ..._image_binary: the raw executable go_binary
    ..._runtime_params.json: runtime config in JSON format

  TODO: use environment_access and app_config.

  """

  # TODO: Parametrise the registry repo prefix.
  repo = "deft-cove-184100/%s_image" % name
  dnsName = name.replace("_", "-")

  go_image(
    name = "%s_image" % name,
    importpath = "unused-for-now",
    library = library,
    visibility = ["//visibility:public"],
    args = args,
    data = files,
    base = base,
  )

  binpath = "%s_image.binary" % name

  if enable_conformance_testing:
    native.sh_test(
      name = "%s_conformance_test" % name,
      data = [ "%s_image.binary" % name ],
      srcs = [ "//testing:http_test.sh" ],
      args = [ "$(location :%s_image.binary)" % name ],
    )

  # Proof-of-concept of how to provide JSON configs to apps.
  native.genrule(
    name = "%s_runtime_params" % name,
    outs = ["%s_runtime_params.json" % name ],
    # TODO: Find a nicer way to dict-to-struct this. Maybe write it out
    # explicitly.
    cmd = "echo '" + struct(prod=environment_access["production"]).to_json() + "' > $@"
  )

  # k8s deployment bits. Ignore this for now please :)

  #image = "%s/%s:latest" % (registry, repo)

  #jsonnet_to_json(
  #    name = "%s_kube_deployment_json" % name,
  #    src = "//bazel:deployment.jsonnet",
  #    deps = ["//bazel:ksonnet-lib"],
  #    outs = [
  #        "%s_kube_deployment.json" % name,
  #    ],
  #    vars = {
  #      "mc_svc": "%s-svc" % dnsName,
  #      "mc_app": "%s-app" % dnsName,
  #      "mc_image": image,
  #    }
  #)

  #k8s_deploy(
  #  name = "%s_kube_deploy" % name,
  #  template = "%s_kube_deployment.json" % name,
  #  # The image_chroot is applied here.
  #  images = {
  #      image : "%s_image" % name
  #  }
  #)
