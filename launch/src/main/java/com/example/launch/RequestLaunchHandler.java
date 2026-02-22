package com.example.launch;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class RequestLaunchHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    private static final ObjectMapper mapper = new ObjectMapper();
    private static final HttpClient httpClient = HttpClient.newHttpClient();

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent event, Context context) {
        try {
            JsonNode body = mapper.readTree(event.getBody());
            String rocketName = body.get("rocketName").asText();
            String destination = body.get("destination").asText();

            String missionControlBaseUrl = System.getenv("MISSION_CONTROL_BASE_URL");
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(missionControlBaseUrl + "/mission/" + rocketName))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            JsonNode mission = mapper.readTree(response.body());
            int progress = mission.get("progress").asInt();
            String status = progress > 0 ? "UNDERWAY" : "LAUNCHING";

            ObjectNode result = mapper.createObjectNode();
            result.put("rocketName", rocketName);
            result.put("destination", destination);
            result.put("status", status);

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
