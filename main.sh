#!/usr/bin/env bash

set -e

export NAMESPACE=ols

function bootstrap() {

  ## Bootstrapping, just first time

  # Create the namespace
  kubectl create namespace $NAMESPACE

  # Use ols as default namespace, this is a security addon
  kubectl config set-context --current --namespace=$NAMESPACE
}

function deploy() {
  ## DEPLOY
  # Create PersistentVolumeClaims
  kubectl apply $(ls configs/*-pvc.yaml | awk ' { print " -f " $1 } ')

  # Configuration files of ontologies
  kubectl apply configmap ols-obo-config --from-file=configs/files/

  # Mongo
  kubectl apply $(ls mongo*.yaml | awk ' { print " -f " $1 } ')

  # SOLR
  kubectl apply $(ls solr*.yaml | awk ' { print " -f " $1 } ')

  # OLS-WEB, depends on mongo and solr,
  kubectl apply $(ls ols-web*.yaml | awk ' { print " -f " $1 } ')

  ## READY
  # Wait to all deployments are ready (by readiness status)
  echo "Waiting all components are ready ..."
  for deployment in mongo solr ols-web; do
    file="${deployment}-deployment.yaml"
    check-deployment $file
  done

  kubectl get all -n $NAMESPACE

}

function check-deployment()
{

  SLEEP_TIME=5
  MAX_ATTEMPTS=50
  ATTEMPTS=0
  READY_REPLICAS="0"
  EXPECTED_REPLICAS=$(kubectl get -n $NAMESPACE -f $1 -o jsonpath='{.spec.replicas}')
  until [[ "$READY_REPLICAS" == "$EXPECTED_REPLICAS" ]]; do
    ATTEMPTS=`expr $ATTEMPTS + 1`
    if [[ $ATTEMPTS -gt $MAX_ATTEMPTS ]]; then
      echo "ERROR: Max number of attempts was reached (${MAX_ATTEMPTS})"
      exit 1
    fi
   READY_REPLICAS=$(kubectl get -n $NAMESPACE -f $1 -o jsonpath='{.status.readyReplicas}' 2>&1)
   echo "[${ATTEMPTS}/${MAX_ATTEMPTS}] - Ready replicas of $1 : ${READY_REPLICAS:-0}/${EXPECTED_REPLICAS} ... "
   sleep $SLEEP_TIME
  done

}

function delete (){
  # Delete all resource under namespace
  kubectl delete "$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all -n $NAMESPACE
}

function port-forward(){
  # SOLR admin console
  kubectl port-forward svc/solr 8983:8983 -n $NAMESPACE &
  # OLS Web
  kubectl port-forward svc/ols-web 8080:8080 -n $NAMESPACE
}

if [[ $# -lt 1 ]]; then
    echo -e "Nothing to do. Type $0 -h for more information"
fi

case "$1" in
    bootstrap)
      shift;
      bootstrap
      ;;
    deploy)
      shift;
      deploy
      ;;
    delete)
      shift;
      delete
      ;;
    port-fwd)
      shift;
      port-forward
      ;;
    --help|-h)
      printf "Usage: $0 arg \n\n"
      printf "Arguments:\n       bootstrap, bootstrapping with all volumes and configurations resources.\n"
      printf "       deploy, deploy all components.\n"
      printf "       delete, delete all.\n"
      printf "       port-fwd, port forwarding of interesting endpoints.\n"
      printf "Example:\n       ./main.sh bootstrap\n"
      ;;
    *)
      >&2 printf "ERROR: Invalid argument $1 \n"
      $0 -h
      exit 1
      ;;
esac
