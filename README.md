# Deploy OLS on k8s

Github page: https://github.com/EBISPOT/OLS

## Getting started with OLS

We have to know the architecture and how these components work beforehand.
After reading the source project in GitHub and its public documentation, let's create a deployment for kubernetes.

## Moving to k8s

There would be, for instance, a coupe of ways to do that:

* Create k8s resources directly. We could use tools like Kompose to convert original docker-compose file to k8s resources and get initial templates.
* More advanced solution than above would be to use Kustomization, a customization tool of kubernetes which
  let's generate or modify resources dynamically.
* If we want an advanced way to provide the OLS stack over kubernetes then we may use Helm (charts) for some 
  components.

For now, I'm going to use a basic approach based on services and deployments resources mainly.

## Deploying resources

For easy full management I've created a script `main.sh` to configure and deploy all components.
This script has some useful internal functions to manage our OLS deployment on kubernetes.
Let's take a look at each stage:

1 - **Bootstrap**

Type this command to create default namespace and setup k8s client (only required once):

`./main.sh bootstrap`

2 - **Deploy**

All resources will be deployed by using this command:

`./main.sh deploy`

We've configured "liveness" and "readiness" probes to check the status letting us 
run OLS when primary services are really ready (avoiding sleeps or locks)

3 - **Port-forwarding**

Since sometimes we don't have access to public endpoints this command does a port forward of Solr and OLS services

`./main.sh port-fwd`


SOLR    --> http://localhost:8983
OLS_WEB --> http://localhost:8080

To check everything were deployed successfully, go to web console and under "Ontologies" section 
you would have to find out the suitable ontology, type in search box any term 
to check solr is working well, finally you could also open the graph view to explore it

4 - **Delete**

With this command we remove all resources on our namespace:

`./main.sh delete`
