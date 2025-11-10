#!/bin/bash
for i in {1..50};
do
    curl --header "Content-Type: application/json" --request POST --data '{"rocketName":"test","destination":"Mars"}' https://kgj0h77o6h.execute-api.eu-central-1.amazonaws.com/test/launch
done