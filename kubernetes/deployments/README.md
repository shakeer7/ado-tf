# Application Deployment

The executable Deployment is owned by helm/sample-application/templates/deployment.yaml.
Use `helm template` to render it into out/. Duplicating its ownership here would
cause Argo/Helm drift. The render and validation script checks both environments.
