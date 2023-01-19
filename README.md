# Introduction 
This repo contains:
1. The scripts for deploying ArgoCD onto a Kubernetes cluster
2. The base application definitions for the pre-requisites on the cluster (e.g. istio, prometheus, etc.)
3. The base application definitions (i.e. the ArgoCD template) for deploying a single Cinchy v5 instance
4. The environment specific kustomizations for every Cinchy v5 cluster managed by ArgoCD

# Managing ArgoCD Repo Credentials
Repository credentials for ArgoCD are managed in k8s secrets. There are 2 repos that ArgoCD requires access to: **cinchy.argocd** and **cinchy.kubernetes**.

The template assumes that a common set of credentials are used by both repos. There are 3 secrets that must be configured which capture the repository URLs and the repository credentials. To configure the secrets, edit the following files:

1. argocd/repo-argocd.yaml
```yaml
#replace the placholder value in the following line
url: <<cinchy.argocd repo url>>

#with the link to the cinchy.argocd git repo, e.g.
url: https://cinchy.visualstudio.com/DevOps/_git/cinchy.argocd
```
2. argocd/repo-kubernetes.yaml
```yaml
#replace the placholder value in the following line
url: <<cinchy.kubernetes repo url>>

#with the link to the cinchy.kubernetes git repo, e.g.
url: https://cinchy.visualstudio.com/DevOps/_git/cinchy.kubernetes
```
3. argocd/repo-credentials.yaml
```yaml
#replace the placholder values in the following lines
url: <<base repo url>>
username: <<git username>>
password: <<git password>>

#with the repo url prefix that is common to both repositories and the credentials, e.g.
url: https://cinchy.visualstudio.com/DevOps/_git
username: my_git_user
password: my_password_here
```

# Deploying ArgoCD
Kustomize is used for the deployment of ArgoCD. Execute the below command in the root directory of this repository to install ArgoCD. This sources the ArgoCD manifests from github, and deploys version 2.1.7

```bash
kubectl apply -k argocd
```

The default username is admin. The password is stored in a secret in the k8s cluster and can be retrieved using the below command

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

To access the ArgoCD portal, a port forward must be set up from the k8s cluster using the following command

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:80 --address 0.0.0.0
```

Once the port forward is established, the ArgoCD portal can be accessed in a local browser at http://0.0.0.0:9090

# ArgoCD App Manifests

## Cluster Components
The common components in each cluster (only installed once per cluster) include:

- Elasticsearch / Fluentbit / Fluentd / Kibana
- Prometheus / Grafana
- Istio
- Kafka
- Redis
- Metrics Server
- Rook
- Velero
- Crunchy PostgreSQL Operator

The base application manifests for these components exist in the ***app_manifests/cluster_components*** directory. Cluster specific configurations are in the ***environment_kustomizations/&lt;cluster name&gt;/cluster_components*** directory.

The ***environment_kustomizations/&lt;cluster name&gt;/cluster_components/patch.yaml*** file must be configured to point to the correct location and revision for the cinchy.kubernetes repo containing the cluster specific configuration, see below for details:

```yaml
#replace the placholder value in the following line
targetRevision: <<target revision>>

#with the name of the branch in the cinchy.kubernetes git repo that contains the configurations for this cluster (or use HEAD), e.g.
targetRevision: HEAD

#replace the placholder value in the following line
repoURL: <<repo url>>

#with the url of the cinchy.kubernetes git repository, e.g.
repoURL: https://cinchy.visualstudio.com/DevOps/_git/cinchy.kubernetes
```

## Cinchy Platform
The Cinchy platform is deployed using the App Of Apps pattern with ArgoCD. There is a two level hierarchy, where the parent is Cinchy and all components are direct children of this one application. The manifest for the Cinchy application is available in the ***app_manifests/cinchy*** directory, and the child applications are in ***app_manifests/platform_components***.

The entry point for deploying an instance is within the ***environment_kustomizations*** directory. The structure is as follows:

```bash
/environment_kustomizations
  /<cluster name>
    /<environment name>
      /cinchy
        kustomization.yaml
        patch.yaml
      /platform_components
        kustomization.yaml
        patch.yaml
```

Within the ***&lt;environment name&gt;*** directory, the ***cinchy*** directory is for the deployment of the parent application, while the ***platform_components*** is all child applications.

The ***environment_kustomizations/&lt;cluster name&gt;/&lt;environment name&gt;/cinchy/patch.yaml*** file must be configured to point to the current location and revision for the cinchy.argocd repo, see below for details:

```yaml
#replace the placholder value in the following line
targetRevision: <<target revision>>

#with the name of the current branch in the cinchy.argocd git repo (or use HEAD), e.g.
targetRevision: HEAD

#replace the placholder value in the following line
repoURL: <<repo url>>

#with the url of the cinchy.argocd git repository, e.g.
repoURL: https://cinchy.visualstudio.com/DevOps/_git/cinchy.argocd
```

The ***environment_kustomizations/&lt;cluster name&gt;/&lt;environment name&gt;/platform_components/patch.yaml*** file must be configured to point to the correct location and revision for the cinchy.kubernetes repo containing the environment specific configuration, see below for details:

```yaml
#replace the placholder value in the following line
targetRevision: <<target revision>>

#with the name of the branch in the cinchy.kubernetes git repo that contains the configurations for this environment (or use HEAD), e.g.
targetRevision: HEAD

#replace the placholder value in the following line
repoURL: <<repo url>>

#with the url of the cinchy.kubernetes git repository, e.g.
repoURL: https://cinchy.visualstudio.com/DevOps/_git/cinchy.kubernetes
```

### Creating a New Cinchy Instance
A new environment can be set up by following the directory structure under **environment_kustomizations** and cloning the kustomization and patch YAML files. 

The ***patch.yaml*** file within the ***cinchy*** directory contains a reference to the ***platform_components*** directory which must be adjusted for any new environment. The destination namespace should also match the environment. See below:

```yaml
#The path attribute must be adjusted to follow the below pattern
path: environment_kustomizations/<<cluster>>/<<environment>>/platform_components

#The namespace should match the environment name
namespace: <<environment>>
```

The ***platform_components/patch.yaml*** file also contains a reference to the destination namespace, which should similarly be updated to match the environment.

The ***platform_components/kustomization.yaml*** file contains a number of patch operations using patchesJson6902 that are updating the **/spec/source/path** property for each of the platform components. They paths follow the same pattern of **environment_kustomizations/&lt;cluster name&gt;/&lt;environment name&gt;/&lt;component name&gt;**. With a new environment, the cluster name and environment name segments must be updated to align with the desired target path in the cinchy.kubernetes repo.

# Deploying a Cinchy v5 Instance

If the common components have not been installed (i.e. this is a new cluster), execute the below command in the root directory of this repository to deploy them via ArgoCD

```bash
kubectl apply -k environment_kustomizations/<cluster name>/cluster_components
```

Execute the below command in the root directory of this repository to deploy a new Cinchy instance, replacing the specific directories for the cluster and environment

```bash
kubectl apply -k environment_kustomizations/<cluster name>/<environment name>/cinchy
kubectl apply -k environment_kustomizations/<cluster name>/<environment name>/platform_components
```
