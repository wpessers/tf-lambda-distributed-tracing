#!/bin/bash
for i in {1..8};
do
    terraform apply -auto-approve

    curl --header "Content-Type: application/json" --request POST --data '{"rocketName":"test","destination":"Mars"}' https://kgj0h77o6h.execute-api.eu-central-1.amazonaws.com/test/launch

    # aws lambda delete-function --function-name request-launch
    # aws lambda delete-function --function-name control-mission
done
