kubectl create namespace development
kubectl create job --from=cronjob/cron-ecr-renew cron-ecr-renew-demo-manual-$(date '+%Y%m%d%H%M%S') -n ns-ecr-renew
kubectl apply -k environment_kustomizations/cinchy-nonprod/development/cinchy
