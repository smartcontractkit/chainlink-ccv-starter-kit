FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild

# Defaults used only by `mpdev verify`, which deploys from schema defaults alone. Ignored by real
# Marketplace deployments, which always supply the form values. See data-test/schema.yaml.
COPY data-test/schema.yaml /data-test/schema.yaml
