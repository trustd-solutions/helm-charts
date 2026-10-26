# Axon Server

A Helm chart for running [Axon Server](https://docs.axoniq.io/reference-guide/axon-server/installation/docker-k8s) on Kubernetes.

## Licensing

Axon Server Enterprise Edition requires a license. This chart supports two licensing modes, selected via `axoniq.axonserver.licensing.mode`:

| Mode       | Description                                                                                          |
| ---------- | ---------------------------------------------------------------------------------------------------- |
| `file`     | Mount a license file from the `axonserver-license` Secret (built from `licenseBase64`). **Default.** |
| `platform` | Authenticate against Axoniq Platform; no license file is required.                                   |

### `file` mode (default)

Provide the license as base64:

```yaml
axoniq:
  axonserver:
    licenseBase64: "<base64-encoded axoniq.license>"
```

The chart creates the `axonserver-license` Secret and mounts it at `<workdir>/license/axoniq.license`, exposing it via the `AXONIQ_LICENSE` environment variable.

### `platform` mode

```yaml
axoniq:
  axonserver:
    licensing:
      mode: platform
      platform:
        authentication: "<environment-id>:<secret>"
        authenticationEnvVar: axoniq_platform_authentication
```

The chart creates the `axonserver-platform-credentials` Secret (key `authentication`) and injects it into the container via the environment variable named by `authenticationEnvVar`.

> **Note:** the environment variable name Axon Server reads for Platform authentication changed across versions. Older releases used `axoniq_console_authentication`; newer releases (2024.2+) use `axoniq_platform_authentication`. Confirm the correct name for your image and set `authenticationEnvVar` accordingly.

## Configuration

| Parameter                                              | Description                                                              | Default                        |
| ------------------------------------------------------ | ------------------------------------------------------------------------ | ------------------------------ |
| `axoniq.axonserver.licensing.mode`                      | Licensing mode: `file` or `platform`                                     | `file`                         |
| `axoniq.axonserver.licensing.platform.authentication`   | `<environment-id>:<secret>` for Axoniq Platform authentication           | `""`                           |
| `axoniq.axonserver.licensing.platform.authenticationEnvVar` | Environment variable name for Platform authentication                | `axoniq_platform_authentication` |

## Upgrading from `0.8.0`

The `0.9.x`/`0.10.0` releases introduced structural changes. When upgrading from `0.8.0`, note:

- `volumeClaimTemplates` no longer uses a per-template `enabled` flag; every entry is a `persistentVolumeClaim`.
- When `aws.azs` is set, PVC `storageClassName` is derived per-AZ (`<app>-<namespace>-<az>`) instead of `defaults.storageClassName`. Existing PVCs are immutable and keep their current storage class; only newly created PVCs are affected.
- `cluster-template.yaml` node names changed from FQDN to short names. If you inject `clusterTemplateBase64` externally, this does not apply.

### Two-stage migration to `platform` licensing

Because `updateStrategy.type` is `OnDelete`, Pods are not recreated automatically on `helm upgrade`.

1. **Stage 1 — structural + licensing feature (keep `mode: file`):** migrate values, upgrade the chart, then manually delete Pods one at a time and verify cluster health.
2. **Stage 2 — flip to `platform`:** set `licensing.mode: platform` and `platform.authentication`, recreate Pods one at a time, and verify the Platform connection before removing the old `axonserver-license` Secret.
