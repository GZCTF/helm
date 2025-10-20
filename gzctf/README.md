# GZCTF Helm Chart
![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
[![Lint and Server-side Dryrun Chart](https://github.com/GZCTF/helm/actions/workflows/lint-and-test-chart.yaml/badge.svg)](https://github.com/GZCTF/helm/actions/workflows/lint-and-test-chart.yaml)

This is a Helm chart for deploying GZCTF on Kubernetes. It deploys the official [GZCTF Docker image](https://ghcr.io/gztimewalker/gzctf/gzctf). Optional HA/Autoscaling (still experimental) + postgresql or postgresql-ha + [Garnet](https://github.com/microsoft/Garnet) or [redis-ha](https://github.com/DandyDeveloper/charts/tree/master/charts/redis-ha) + [MinIO S3](https://github.com/minio/minio/tree/master/helm/minio). Also supports using external Postgresql/Redis/S3.

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

## Info
- multi-node is still experimental (needs extensive testing)
- postgresql-ha bitnami image is legacy/deprecated

## Values examples

### Deploy Postgresql + Garnet + Minio
```yaml
gzctf:
  image:
    tag: "latest"
  appsettings: |
    {
      "AllowedHosts": "*",
      "ConnectionStrings": {
        "Database": "Host=gzctf-db:5432;Database=gzctf;Username=postgres;Password=gzctf",
        "RedisCache": "gzctf-garnet:6379,password=gzctf",
        "Storage": "minio.s3://serviceUrl=gzctf-minio;keyId=gzctf;key=gzctf;bucket=gzctf-bucket"
      },
      ...
    } # content of appsettings.json
  env:
    - name: LC_ALL
      value: "en_US.UTF-8"
    - name: GZCTF_ADMIN_PASSWORD
      value: "astrongpassword"
  autoscaling:
    enabled: false # (set to true for multi-node. still experimental)
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
    targetMemoryUtilizationPercentage: 80

garnet:
  enabled: true
  config:
    garnetConf: |
     {
       "AuthenticationMode": "Password",
       "Password": "gzctf" # needs to be consistent with the RedisCache password in appsettings.json
     }

redis-ha:
  enabled: false # (Can be enabled instead of garnet. Configure your appsettings to connect to release-name-redis-ha-haproxy )

postgresql:
  enabled: true
  env:
    - name: POSTGRES_PASSWORD
      value: gzctf # needs to be consistent with the database password in appsettings.json
  persistence:
    enabled: true
    size: 2Gi

minio:
  enabled: true
  persistence:
    size: 10Gi
  rootUser: gzctf
  rootPassword: gzctf # needs to be consistent with the MinIO.S3 password in appsettings.json
```

### Configure your own external DB/Redis/S3
```yaml
GZCTF:
  image:
    tag: "latest"
  appsettings: |
    {
      "AllowedHosts": "*",
      "ConnectionStrings": {
        "Database": "Host=...;Database=...;Username=...;Password=...",
        "RedisCache": "...,password=...",
        "Storage": "minio.s3://serviceUrl=...;keyId=...;key=...;bucket=..."
      },
      ...
    } # content of appsettings.json

postgresql:
  enabled: false
garnet:
  enabled: false
minio:
  enabled: false
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql-ha | 16.3.2 |
| https://charts.min.io | minio(minio) | 5.4.0 |
| https://dandydeveloper.github.io/charts | redis-ha | 4.33.7 |
| oci://ghcr.io/microsoft/helm-charts | garnet | 0.2.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraObjects | list | [] | Additional Kubernetes manifests to deploy with this Helm chart |
| garnet.config.existingSecret | string | `""` | Garnet secret (if you want to use an existing secret). This secret must contains a key called 'garnet.conf'. |
| garnet.config.garnetConf | string | `"{\n  \"AuthenticationMode\": \"Password\",\n  \"Password\": \"gzctf\"\n}\n"` | The garnet.conf data content. |
| garnet.enabled | bool | `false` | Enable Microsoft Garnet cache-store deployment |
| garnet.image | object | `{"registry":"ghcr.io","repostiory":"microsoft/garnet","tag":""}` | Garnet container image configuration |
| garnet.image.registry | string | `"ghcr.io"` | Garnet image registry |
| garnet.image.repostiory | string | `"microsoft/garnet"` | Garnet image repository |
| garnet.image.tag | string | `""` | Garnet image tag (empty string uses chart appVersion) |
| garnet.persistence | object | Disabled (persistence not needed for cache) | Persistent storage configuration for Garnet |
| garnet.persistence.enabled | bool | `false` | Enable persistent storage for Garnet (not recommended for cache workloads) |
| gzctf.affinity | object | `{}` | Affinity rules for GZCTF pod scheduling |
| gzctf.appsettings | string | See values.yaml for full configuration | GZCTF application settings (appsettings.json content) |
| gzctf.autoscaling.enabled | bool | `false` | Enable autoscaling |
| gzctf.autoscaling.maxReplicas | int | `100` | Maximum number of replicas |
| gzctf.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| gzctf.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| gzctf.autoscaling.targetMemoryUtilizationPercentage | int | `80` | Target memory utilization percentage |
| gzctf.clusterRole.create | bool | `true` | Create ClusterRole for GZCTF (required for Kubernetes challenge container management) |
| gzctf.clusterRole.rules | list | `[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["*"],"verbs":["*"]}]` | ClusterRole rules (full cluster access for managing challenge containers) |
| gzctf.env | list | `[{"name":"GZCTF_ADMIN_PASSWORD","value":"xxx"},{"name":"LC_ALL","value":"en_US.UTF-8"}]` | Environment variables for GZCTF container |
| gzctf.env[0] | object | `{"name":"GZCTF_ADMIN_PASSWORD","value":"xxx"}` | Initial admin password for GZCTF |
| gzctf.env[1] | object | `{"name":"LC_ALL","value":"en_US.UTF-8"}` | Locale configuration |
| gzctf.fullnameOverride | string | `""` | Override the full name of the chart |
| gzctf.image | object | `{"pullPolicy":"Always","repository":"ghcr.io/gztimewalker/gzctf/gzctf","tag":"v1.6.2"}` | GZCTF container image configuration |
| gzctf.image.pullPolicy | string | `"Always"` | Image pull policy |
| gzctf.image.repository | string | `"ghcr.io/gztimewalker/gzctf/gzctf"` | GZCTF image repository |
| gzctf.image.tag | string | `"v1.6.2"` | GZCTF image tag |
| gzctf.imagePullSecrets | list | `[]` | Image pull secrets for private container registries |
| gzctf.ingress.annotations | object | `{"traefik.ingress.kubernetes.io/service.sticky.cookie":"true","traefik.ingress.kubernetes.io/service.sticky.cookie.httponly":"true","traefik.ingress.kubernetes.io/service.sticky.cookie.name":"LB_Session"}` | Annotations for ingress resource |
| gzctf.ingress.className | string | `""` | Ingress class name |
| gzctf.ingress.enabled | bool | `true` | Enable ingress for GZCTF |
| gzctf.ingress.hosts | list | `[{"host":"ctf.example.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts configuration |
| gzctf.ingress.tls | list | `[]` | TLS configuration for ingress |
| gzctf.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"metrics"}}` | Liveness probe configuration |
| gzctf.metrics.enabled | bool | `true` | Enable metrics port |
| gzctf.metrics.port | int | `3000` | Metrics port number |
| gzctf.nameOverride | string | `""` | Override the name of the chart |
| gzctf.nodeSelector | object | `{}` | Node labels for GZCTF pod assignment |
| gzctf.podAnnotations | object | `{}` | Annotations to add to GZCTF pods |
| gzctf.podLabels | object | `{}` | Labels to add to GZCTF pods |
| gzctf.podSecurityContext | object | `{}` | Security context for GZCTF pod |
| gzctf.pvc.accessMode | string | `"ReadWriteOnce"` | Access mode for the PVC (use ReadWriteMany when deploying multiple instances) |
| gzctf.pvc.create | bool | `true` | Create a PVC for GZCTF |
| gzctf.pvc.size | string | `"2Gi"` | Size of the PVC |
| gzctf.pvc.storageClassName | string | `"standard"` | Storage class name for the PVC (empty string uses cluster default) |
| gzctf.readinessProbe | object | `{"httpGet":{"path":"/healthz","port":"metrics"}}` | Readiness probe configuration |
| gzctf.replicaCount | int | `1` | Number of GZCTF replicas (Set to >1 for multi-node. Needs requirements) |
| gzctf.resources | object | `{"requests":{"cpu":"1000m","memory":"384Mi"}}` | Resource requests and limits for GZCTF container |
| gzctf.resources.requests | object | `{"cpu":"1000m","memory":"384Mi"}` | Resource requests |
| gzctf.resources.requests.cpu | string | `"1000m"` | CPU request |
| gzctf.resources.requests.memory | string | `"384Mi"` | Memory request |
| gzctf.securityContext | object | `{}` | Security context for GZCTF container |
| gzctf.service | object | `{"annotations":{},"port":8080,"type":"ClusterIP"}` | GZCTF service configuration |
| gzctf.service.annotations | object | `{}` | Annotations to add to the service |
| gzctf.service.port | int | `8080` | Service port |
| gzctf.service.type | string | `"ClusterIP"` | Service type |
| gzctf.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for GZCTF |
| gzctf.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| gzctf.serviceAccount.automount | bool | `true` | Automatically mount ServiceAccount token |
| gzctf.serviceAccount.create | bool | `true` | Create a ServiceAccount for GZCTF |
| gzctf.serviceAccount.name | string | `""` | ServiceAccount name (generated from chart fullname if not set) |
| gzctf.strategyType | string | `"RollingUpdate"` | Deployment strategy type |
| gzctf.tolerations | list | `[]` | Tolerations for GZCTF pod scheduling |
| gzctf.volumeMounts | list | `[]` | Additional volume mounts for GZCTF container |
| gzctf.volumes | list | `[]` | Additional volumes for GZCTF pod |
| minio.buckets | list | `[{"name":"gzctf-bucket","policy":"download","purge":false}]` | MinIO bucket configuration |
| minio.buckets[0] | object | `download` policy means this bucket is readonly for anonymous access (competitors) | Default bucket to be used by GZCTF |
| minio.buckets[0].policy | string | `"download"` | Bucket access policy (download = readonly for anonymous users) |
| minio.buckets[0].purge | bool | `false` | Whether to purge the bucket on deletion |
| minio.drivesPerNode | int | `1` | Number of drives per MinIO replica/node |
| minio.enabled | bool | `false` | Enable MinIO deployment (set to false if you want to use an external S3 bucket) |
| minio.ingress.annotations | object | `{}` | Annotations for MinIO ingress |
| minio.ingress.enabled | bool | `true` | Enable ingress for MinIO |
| minio.ingress.hosts | list | `["minio.example.com"]` | Hostnames for MinIO ingress |
| minio.persistence | object | `{"size":"10Gi"}` | MinIO persistent storage configuration |
| minio.persistence.size | string | `"10Gi"` | Size of persistent volume for each MinIO instance (adjust according to your needs) |
| minio.replicas | int | `3` | Number of MinIO replicas/nodes |
| minio.resources | object | `{"requests":{"memory":"2Gi"}}` | Resource requests and limits for MinIO |
| minio.resources.requests | object | `{"memory":"2Gi"}` | Resource requests for MinIO |
| minio.resources.requests.memory | string | `"2Gi"` | Memory request for MinIO |
| minio.rootPassword | string | `"gzctf"` | MinIO password |
| minio.rootUser | string | `"gzctf"` | MinIO user |
| postgresql-ha.enabled | bool | `false` | Enable or disable PostgreSQL HA deployment (THIS USES BITNAMI LEGACY IMAGES BY DEFAULT WHICH NO LONGER RECIEVE RPOPER SECURITY UPDATES) |
| postgresql-ha.image.registry | string | `"docker.io"` | Docker registry for PostgreSQL image |
| postgresql-ha.image.repository | string | `"bitnamilegacy/postgresql-repmgr"` | PostgreSQL repository (legacy repmgr version) |
| postgresql-ha.image.tag | string | `"17.6.0-debian-12-r2"` | PostgreSQL image tag (version 17.6.0) |
| postgresql-ha.persistence.accessMode | string | `"ReadWriteOnce"` | Volume access mode |
| postgresql-ha.persistence.enabled | bool | `true` | Enable persistent volume for database storage |
| postgresql-ha.persistence.size | string | `"2Gi"` | Persistent volume size |
| postgresql-ha.persistence.storageClass | string | `""` | Storage class name (empty string uses cluster default) |
| postgresql-ha.postgresql.database | string | `"gzctf"` | Default database name to create |
| postgresql-ha.postgresql.password | string | `"gzctf"` | PostgreSQL superuser password (should be overridden or use secrets) |
| postgresql-ha.postgresql.username | string | `"postgres"` | PostgreSQL superuser username |
| postgresql-ha.volumePermissions.enabled | bool | `true` | Enable init container to set proper volume permissions |
| postgresql.affinity | object | `{}` | Affinity rules for PostgreSQL pod scheduling |
| postgresql.enabled | bool | `true` | Enable PostgreSQL deployment |
| postgresql.env | list | `[{"name":"POSTGRES_PASSWORD","value":"gzctf"}]` | Environment variables for PostgreSQL container |
| postgresql.env[0] | object | Must match the database password in appsettings.json | PostgreSQL password environment variable |
| postgresql.image | object | `{"imagePullSecrets":[],"pullPolicy":"IfNotPresent","registry":"docker.io","repository":"postgres","tag":"16-alpine"}` | PostgreSQL image configuration |
| postgresql.image.imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| postgresql.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| postgresql.image.registry | string | `"docker.io"` | Docker registry for PostgreSQL image |
| postgresql.image.repository | string | `"postgres"` | PostgreSQL image repository |
| postgresql.image.tag | string | `"16-alpine"` | PostgreSQL image tag |
| postgresql.livenessProbe | object | `{}` | Liveness probe configuration for PostgreSQL container |
| postgresql.nodeSelector | object | `{}` | Node labels for PostgreSQL pod assignment |
| postgresql.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for the persistent volume |
| postgresql.persistence.enabled | bool | `true` | Enable persistent storage for PostgreSQL |
| postgresql.persistence.size | string | `"2Gi"` | Size of the persistent volume |
| postgresql.persistence.storageClassName | string | `""` | Storage class name for persistent volume (empty string uses cluster default) |
| postgresql.podAnnotations | object | `{}` | Annotations to add to PostgreSQL pods |
| postgresql.podLabels | object | `{}` |  |
| postgresql.podSecurityContext | object | `{}` | Security context for PostgreSQL pod |
| postgresql.readinessProbe | object | `{}` | Readiness probe configuration for PostgreSQL container |
| postgresql.resources | object | `{"requests":{"cpu":"500m","memory":"512Mi"}}` | Resource requests and limits for PostgreSQL container |
| postgresql.resources.requests | object | `{"cpu":"500m","memory":"512Mi"}` | Resource requests |
| postgresql.resources.requests.cpu | string | `"500m"` | CPU request |
| postgresql.resources.requests.memory | string | `"512Mi"` | Memory request |
| postgresql.securityContext | object | `{}` | Security context for PostgreSQL container |
| postgresql.service | object | `{"port":5432}` | PostgreSQL service configuration |
| postgresql.service.port | int | `5432` | PostgreSQL service port |
| postgresql.tolerations | list | `[]` | Tolerations for PostgreSQL pod scheduling |
| postgresql.volumeMounts | list | `[]` | Additional volume mounts for PostgreSQL container |
| postgresql.volumes | list | `[]` | Additional volumes for PostgreSQL pod |
| redis-ha.additionalAffinities | object | `{}` | Additional affinities to add to the Redis server pods. |
| redis-ha.affinity | string | `""` | Assign custom [affinity] rules to the Redis pods. |
| redis-ha.auth | bool | `true` | Configures redis-ha with AUTH |
| redis-ha.containerSecurityContext | object | See [values.yaml] | Redis HA statefulset container-level security context |
| redis-ha.enabled | bool | `false` | Deploys a High-Availability Redis cluster |
| redis-ha.exporter.enabled | bool | `false` | Enable Prometheus redis-exporter sidecar |
| redis-ha.exporter.image | string | `"ghcr.io/oliver006/redis_exporter"` | Repository to use for the redis-exporter |
| redis-ha.exporter.tag | string | `"v1.78.0"` | Tag to use for the redis-exporter |
| redis-ha.haproxy.additionalAffinities | object | `{}` | Additional affinities to add to the haproxy pods. |
| redis-ha.haproxy.affinity | string | `""` | Assign custom [affinity] rules to the haproxy pods. |
| redis-ha.haproxy.containerSecurityContext | object | See [values.yaml] | HAProxy container-level security context |
| redis-ha.haproxy.enabled | bool | `true` | Enabled HAProxy LoadBalancing/Proxy |
| redis-ha.haproxy.hardAntiAffinity | bool | `true` | Whether the haproxy pods should be forced to run on separate nodes. |
| redis-ha.haproxy.labels | object | `{"app.kubernetes.io/name":"gzctf-redis-ha-haproxy"}` | Custom labels for the haproxy pod. |
| redis-ha.haproxy.metrics.enabled | bool | `true` | HAProxy enable prometheus metric scraping |
| redis-ha.haproxy.tolerations | list | `[]` | [Tolerations] for use with node taints for haproxy pods. |
| redis-ha.hardAntiAffinity | bool | `true` | Whether the Redis server pods should be forced to run on separate nodes. |
| redis-ha.image.repository | string | `"public.ecr.aws/docker/library/redis"` | Redis repository |
| redis-ha.image.tag | string | `"7.2.11-alpine"` | Redis tag |
| redis-ha.persistentVolume.enabled | bool | `false` | Configures persistence on Redis nodes |
| redis-ha.redis.config | object | See [values.yaml] | Any valid redis config options in this section will be applied to each server (see `redis-ha` chart) |
| redis-ha.redis.config.save | string | `'""'` | Will save the DB if both the given number of seconds and the given number of write operations against the DB occurred. `""`  is disabled |
| redis-ha.redis.masterGroupName | string | `"gzctf"` | Redis convention for naming the cluster group: must match `^[\\w-\\.]+$` and can be templated |
| redis-ha.redisPassword | string | `"gzctf"` | A password that configures a `requirepass` and `masterauth` in the conf parameters (Requires `auth: enabled`) |
| redis-ha.tolerations | list | `[]` | [Tolerations] for use with node taints for Redis pods. |
| redis-ha.topologySpreadConstraints | object | `{"enabled":false,"maxSkew":"","topologyKey":"","whenUnsatisfiable":""}` | Assign custom [TopologySpreadConstraints] rules to the Redis pods. # https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ |
| redis-ha.topologySpreadConstraints.enabled | bool | `false` | Enable Redis HA topology spread constraints |
| redis-ha.topologySpreadConstraints.maxSkew | string | `""` (defaults to `1`) | Max skew of pods tolerated |
| redis-ha.topologySpreadConstraints.topologyKey | string | `""` (defaults to `topology.kubernetes.io/zone`) | Topology key for spread |
| redis-ha.topologySpreadConstraints.whenUnsatisfiable | string | `""` (defaults to `ScheduleAnyway`) | Enforcement policy, hard or soft |

Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs)