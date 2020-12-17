#!/bin/bash
set -x
IMAGE=hello-world-11
SVC=flask-svc-11

docker build -t $IMAGE .

# Prerequisite: Install the updated awscli tool  and install lightsail container plugin for AWS CLI https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-install-software
URL=$(aws lightsail create-container-service --service-name $SVC --power nano --scale 1 | jq -r '.containerService.url' )

PUSH_OUTPUT=$(aws lightsail push-container-image --service-name $SVC --image $IMAGE --label $IMAGE )
SVC_IMG=$(echo $PUSH_OUTPUT |sed -n  "s/^.*Refer to this image as \"\(.*\)\" in deployments\..*/\1/p" )


read -r -d '' LC_JSON <<-EOT
 {
      "serviceName": "$SVC",
      "containers": {
         "$IMAGE": {
            "image": "$SVC_IMG",
            "ports": {
               "8080": "HTTP"
            }
         }
     },
     "publicEndpoint": {
        "containerName": "$IMAGE",
        "containerPort": 8080
     }
  }
EOT

echo $LC_JSON | jq . > lc.json

aws lightsail create-container-service-deployment --cli-input-json file://lc.json

while [ -n "$(curl -L --silent $URL |grep 404)" ];
do
    sleep 1
done

curl -L --silent $URL
