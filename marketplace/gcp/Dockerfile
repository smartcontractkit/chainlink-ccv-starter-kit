ARG MARKETPLACE_TOOLS_TAG=latest

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

# Production chart tarball (mirrors what the helm onbuild base would have produced).
RUN helm package chart --dependency-update --destination /tmp/chart \
    && mv /tmp/chart/*.tgz /chart.tar.gz

# Verify chart: deep-merge overlay values into the chart's values, add overlay templates, re-tar.
RUN mkdir -p /work/test \
    && cp -r chart /work/test/chart \
    && yq eval-all 'select(fi==0) * select(fi==1)' \
         chart/values.yaml data-test/chart-overlay/values.yaml > /work/test/chart/values.yaml \
    && cp data-test/chart-overlay/templates/* /work/test/chart/templates/ \
    && tar -czf /chart-test.tar.gz -C /work/test chart

# publishedVersion in both schemas is envsubst'd from $TAG (matches the helm onbuild behavior).
RUN env -i "REGISTRY=${REGISTRY}" "TAG=${TAG}" envsubst < schema.yaml > /schema.yaml \
    && env -i "REGISTRY=${REGISTRY}" "TAG=${TAG}" envsubst < data-test/schema.yaml > /schema-test.yaml

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:$MARKETPLACE_TOOLS_TAG

COPY --from=build /chart.tar.gz /data/chart/chart.tar.gz
COPY --from=build /schema.yaml /data/schema.yaml
COPY --from=build /chart-test.tar.gz /data-test/chart/chart.tar.gz
COPY --from=build /schema-test.yaml /data-test/schema.yaml
