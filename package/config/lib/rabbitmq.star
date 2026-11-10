load("@ytt:data", "data")
load("@ytt:struct", "struct")

# ###########
# OPERATOR
# ###########

# The names of the operator resources in the upstream manifest.
deployment = "rabbitmq-cluster-operator"
container = "operator"
image_pull_secret_name = "canonical-registry-credentials"

# The labels selecting the operator Pods, as in the upstream Deployment.
selector = {"app.kubernetes.io/name": "rabbitmq-cluster-operator"}

def _join(values):
  return ",".join(values)
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# ###########
# CONFIGURATION
# ###########

# The operator configuration computed from the package values. `env` is merged on top of it.
# The operator reads it from environment variables, at startup. Variables set to null are kept in the result,
# so that the merge removes them from the upstream ones too.
# See: https://www.rabbitmq.com/kubernetes/operator/configure-operator-defaults
def operator_env():
  values = data.values
  env = {}
  if values.watch_namespaces:
    env["OPERATOR_SCOPE_NAMESPACE"] = _join(values.watch_namespaces)
  end
  if values.defaults.image:
    env["DEFAULT_RABBITMQ_IMAGE"] = values.defaults.image
  end
  if values.defaults.image_pull_secrets:
    env["DEFAULT_IMAGE_PULL_SECRETS"] = _join(values.defaults.image_pull_secrets)
  end

  for name, value in struct.decode(values.env).items():
    env[name] = value
  end
  return env
end

# Merges the given variables into the upstream ones, keeping their order. New variables are appended,
# and variables set to null are removed. The upstream `OPERATOR_NAMESPACE` is read from the Pod metadata.
def _merge_env(upstream, overrides):
  merged = []
  for var in upstream:
    name = var["name"]
    if name not in overrides:
      merged.append(var)
    elif overrides[name] != None:
      merged.append({"name": name, "value": _format(overrides[name])})
    end
  end
  upstream_names = [var["name"] for var in upstream]
  for name, value in overrides.items():
    if name not in upstream_names and value != None:
      merged.append({"name": name, "value": _format(value)})
    end
  end
  return merged
end

# The `via` function of the overlay replacing the upstream container env.
def env_merger(overrides):
  return lambda left, _: _merge_env(left, overrides)
end

# ###########
# FLAGS
# ###########

# The flags computed from the package values. `args` is merged on top of them.
def operator_args():
  args = {"zap-log-level": data.values.observability.logging.level}
  for name, value in struct.decode(data.values.args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

# Merges the given flags into the upstream ones, keeping their order. New flags are appended,
# and flags set to null are removed. The flags without a value are kept as they are.
def _merge_args(upstream, overrides):
  flags = {}
  for arg in upstream:
    name, separator, value = arg.lstrip("-").partition("=")
    flags[name] = value if separator else None
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return ["--" + name if value == None else "--" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlay replacing the upstream container args.
def args_merger(overrides):
  return lambda left, _: _merge_args(left, overrides)
end
