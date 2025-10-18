# GZCTF Helm Chart
[![Lint and Server-side Dryrun Chart](https://github.com/GZCTF/helm/actions/workflows/lint-and-test-chart.yaml/badge.svg)](https://github.com/GZCTF/helm/actions/workflows/lint-and-test-chart.yaml)

This is a Helm chart for deploying GZCTF on Kubernetes. It deploys the official [GZCTF Docker image](ghcr.io/gztimewalker/gzctf/gzctf). Optional HA/Autoscaling (still experimental) + postgresql or postgresql-ha + [Garnet](https://github.com/microsoft/Garnet) or [redis-ha](https://github.com/DandyDeveloper/charts/tree/master/charts/redis-ha) + [MinIO S3](https://github.com/minio/minio/tree/master/helm/minio). Also supports using external Postgresql/Redis/S3.

## Add the helm repo
```bash
helm repo add gzctf https://gzctf.github.io/helm
```
## Install (Quick start)

This installs a single-node gzctf with ReadWriteOnce PVC and a single replica of postgresql (statefulset). appsettings has the default configurations
```bash
helm install gzctf gzctf/gzctf \
  --set env[0].name=GZCTF_ADMIN_PASSWORD \
  --set env[0].value=xxx
```
## Install with custom values.yaml

If you need to install garnet or redis-ha and/or postgresql-ha and/or MinIO. Also if you need to set passwords/xorkey
```bash
helm install gzctf gzctf/gzctf -f values.yaml
```

## Install from source

Build helm dependencies before installing the chart.

```bash
helm dependency update
```

Set the values in `values.yaml` to your desired configuration. Then install

```bash
helm install release-name . -f values.yaml --create-namespace --namespace gzctf
```

## Uninstall
```bash
helm uninstall release-name --namespace gzctf
```
