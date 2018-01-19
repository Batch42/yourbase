load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")
load("@io_bazel_rules_docker//go:image.bzl", "go_image")
load(
    "@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl",
    "jsonnet_library",
    "jsonnet_to_json",
)

load(":secrets.bzl", "expand_secrets")

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")
load("//:k8s.bzl", "image_chroot", "cluster")

def go_http_server(name, library=None, environment_access=None, app_config=None,
  args=None, files=None, base=None, enable_uniformity_testing=True, secrets=[]):
  """Create a deployable Go server with bells and whistles.

  Arguments:
    - name: it must be a *globally unique name* in the cloud namespace.
    - files: additional files to add to the server
    - base: alternative base container image. Useful if you need a richer
      system including a shell.
    - enable_uniformity_testing: if enabled, run uniformity tests again this
      server.
    - secrets: list of string of secrets we import from a local file. Requires
      a "secrets" repository defined in the WORKSPACE.

  Output:
    ..._image: container image
    ..._image_binary: the raw executable go_binary
    ..._runtime_params.json: runtime config in JSON format

  TODO: use environment_access and app_config.

  """

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

  if enable_uniformity_testing:
    go_test(
      name = "%s_uniformity_test" % name,
      embed = [ "//testing:http_uniformity_lib"],
      data = [
          "%s_image.binary" % name,
      ],
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

  expand_secrets(name, secrets)

  repo = "deft-cove-184100/" + name + "_image"
  dnsName = name.replace("_", "-")

  # TODO: add the BUILD_USER to the image path, so people don't
  # publish images on other people's directories.
  # img = image_chroot.replace("{BUILD_USER}", "$(BUILD_USER)")
  # I think we need go_http_server to be a rule and not a macro, so we can do 
  # something like ctx.action.expand_template.
  img = "%s/%s_image:latest" % (image_chroot, name)

  jsonnet_to_json(
      name = name + "_kube_deployment_json",
      src = "//bazel/templates:deployment.jsonnet",
      deps = ["//bazel:ksonnet-lib"],
      outs = [
          name + "_kube_deployment.json",
      ],
      vars = {
        "mc_svc": dnsName + "-svc",
        "mc_app": dnsName + "-app",
        "mc_image": img,
      }
  )

  k8s_deploy(
    name = name + "_deploy",
    template = name + "_kube_deployment.json",
    # The image_chroot is applied here.
    images = {
       img : name + "_image",
    }
  )