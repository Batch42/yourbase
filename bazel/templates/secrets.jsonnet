local k = import "external/com_github_ksonnet_lib/ksonnet.beta.2/k.libsonnet";
local g = import "external/secrets/github.jsonnet";

local secret = k.core.v1.secret;

local appSecrets = secret.new();

{
	Kind: "Secret",
	metadata: { name: std.extVar("secret_name") },
	type: "Opaque",
	data: g
}
