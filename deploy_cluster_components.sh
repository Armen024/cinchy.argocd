kubectl apply -k environment_kustomizations/nonprod/cluster_components
kubectl label namespace argocd istio-injection=enabled
