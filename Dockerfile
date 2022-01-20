ARG BASE_IMAGE=apachepulsar/pulsar:2.8.1
FROM debian:stretch-slim as tf

ARG TERRAFORM_VERSION=1.1.2
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION}
RUN ARCH=$(if [ $(uname -m) = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    apt-get update && apt-get install -y curl unzip  && rm -rf /var/lib/apt/lists/* && \
    curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip
RUN chmod +x terraform

FROM ${BASE_IMAGE}

COPY --from=tf terraform /bin/terraform

COPY ./terraform-pulsar-plugin terraform.d/
COPY ./*.tf ./
COPY wait-for-it-api.sh ./
COPY ./conf/standalone.conf /pulsar/conf/standalone.conf

ENV PULSAR_MEM="-XX:InitialRAMPercentage=20.0 -XX:MaxRAMPercentage=20.0 -XX:MinRAMPercentage=20.0 -Xms1g -Xmx1g -XX:MaxDirectMemorySize=1g"
# pulsar is starded in background and its process id is stored to kill it once finished.
# terraform is initiated.
# then we wait until pulsar is ready before running terraform and applying our infrastructure on top of it.
# once we are done, we can kill the instance.

RUN ./bin/pulsar standalone > /dev/null & \
    export PROCESS_ID=$! && \
    terraform init && \
    ./wait-for-it-api.sh http://127.0.0.1:8080/admin/v2/brokers/ready/ -s -t 240 -- \
        terraform apply -auto-approve -var pulsar_service_url="http://127.0.0.1:8080" && \
    kill $PROCESS_ID && \
    bash -c 'while kill -0 $PROCESS_ID; do echo "Process $PROCESS_ID is still alive"; sleep 5; done' && \
    rm -rf /bin/terraform && \
    rm -rf ./terraform-pulsar-plugin && \
    rm -f wait-for-it-api.sh && \
    rm -rf ./*.tf

ENTRYPOINT ["bin/pulsar", "standalone"]
