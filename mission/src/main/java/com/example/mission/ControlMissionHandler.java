package com.example.mission;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.GetItemRequest;
import software.amazon.awssdk.services.dynamodb.model.GetItemResponse;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;

import java.util.Map;

public class ControlMissionHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    private static final ObjectMapper mapper = new ObjectMapper();
    private static final DynamoDbClient dynamoDb = DynamoDbClient.builder()
            .region(Region.EU_CENTRAL_1)
            .build();

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent event, Context context) {
        try {
            String rocketName = event.getPathParameters().get("rocketName");
            if (rocketName == null) {
                throw new IllegalArgumentException("No rocket name specified");
            }

            GetItemResponse response = dynamoDb.getItem(GetItemRequest.builder()
                    .tableName("Mission")
                    .key(Map.of("RocketName", AttributeValue.builder().s(rocketName).build()))
                    .build());

            if (!response.hasItem() || response.item().isEmpty()) {
                dynamoDb.putItem(PutItemRequest.builder()
                        .tableName("Mission")
                        .item(Map.of(
                                "RocketName", AttributeValue.builder().s(rocketName).build(),
                                "Destination", AttributeValue.builder().s("Mars").build(),
                                "Progress", AttributeValue.builder().n("0").build()
                        ))
                        .build());
            }

            ObjectNode result = mapper.createObjectNode();
            result.put("destination", "Mars");
            result.put("progress", 10);

            return new APIGatewayProxyResponseEvent()
                    .withStatusCode(200)
                    .withBody(mapper.writeValueAsString(result));
        } catch (Exception e) {
            return new APIGatewayProxyResponseEvent()
                    .withStatusCode(500)
                    .withBody("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}
