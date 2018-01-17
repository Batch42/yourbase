secrets_build_file = '''
load(
    "@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl",
        "jsonnet_library",
)
jsonnet_library(
    name = "secrets",
    srcs = glob([
        "*.jsonnet",
    ]),
    visibility = ["//visibility:public"],
)
'''

# Files in this directory must be named "secret_name.jsonnet" and the content
# of the file will become the `data` section of the kubernetes secret.
def secret_repo(name, path):
  native.new_local_repository(
    name = name,
    path = path,
    build_file_content = secrets_build_file,
)
