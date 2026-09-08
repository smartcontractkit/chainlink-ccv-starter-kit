ARG DEPLOYER_BASE=gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest

FROM alpine:3 AS build

RUN apk add --no-cache yq tar gettext helm

WORKDIR /work
COPY marketplace/gcp/chart/ccv-cell-mp ./chart
COPY marketplace/gcp/schema.yaml ./schema.yaml
COPY marketplace/gcp/data-test ./data-test
COPY charts/ccv-cell /charts/ccv-cell

ARG REGISTRY
ARG TAG

# Application descriptor version must equal schema publishedVersion (the tag).
RUN sed -i "s/^appVersion:.*/appVersion: \"${TAG}\"/" chart/Chart.yaml

# Production chart tarball: helm package to vendor dependencies, then repack under the 'chart/'
# root that the deployer base hardcodes (extracted/<name>/chart/).
RUN helm package chart --dependency-update --destination /tmp/chart \
    && mkdir /tmp/repack \
    && tar -xzf /tmp/chart/*.tgz -C /tmp/repack \
    && mv /tmp/repack/$(ls /tmp/repack) /tmp/repack/chart \
    && tar -czf /chart.tar.gz -C /tmp/repack chart

# Verify chart: deep-merge overlay values into the chart's values, add overlay templates, re-tar.
RUN mkdir -p /work/test \
    && cp -r chart /work/test/chart \
    && yq eval-all 'select(fi==0) * select(fi==1)' \
         chart/values.yaml data-test/chart-overlay/values.yaml > /work/test/chart/values.yaml \
    && cp data-test/chart-overlay/templates/* /work/test/chart/templates/ \
    && tar -czf /chart-test.tar.gz -C /work/test chart

# publishedVersion in both schemas is envsubst'd from $TAG (matches the helm onbuild behavior).
# GCP schema validator requires semver without the leading 'v'.
RUN env -i "REGISTRY=${REGISTRY}" "TAG=${TAG#v}" envsubst < schema.yaml > /schema.yaml \
    && env -i "REGISTRY=${REGISTRY}" "TAG=${TAG#v}" envsubst < data-test/schema.yaml > /schema-test.yaml

FROM $DEPLOYER_BASE

COPY --from=build /chart.tar.gz /data/chart/chart.tar.gz
COPY --from=build /schema.yaml /data/schema.yaml
COPY --from=build /chart-test.tar.gz /data-test/chart/chart.tar.gz
COPY --from=build /schema-test.yaml /data-test/schema.yaml
