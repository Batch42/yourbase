load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")
load("@io_bazel_rules_docker//go:image.bzl", "go_image", )
load(
    "@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl",
    "jsonnet_library",
    "jsonnet_to_json",
)

def go_http_server(name, library=None, environment_access=None, app_config=None,
  args=None, files=None, base=None, enable_uniformity_testing=True):
  """Create a deployable Go server with bells and whistles.

  Arguments:
    - name: it must be a *globally unique name* in the cloud namespace.
    - files: additional files to add to the server
    - base: alternative base container image. Useful if you need a richer
      system including a shell.
    - enable_uniformity_testing: if enabled, run uniformity tests again this
      server.

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
