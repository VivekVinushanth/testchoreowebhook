import ballerinax/trigger.asgardeo;
import ballerina/log;
// import ballerina/email;
import ballerina/http;
import ballerina/oauth2;

configurable asgardeo:ListenerConfig config = ?;

listener http:Listener httpListener = new (8090);
listener asgardeo:Listener webhookListener = new (config, httpListener);
http:Client idvClient = check new ("https://verify.api.demo.evidentid.com", auth = {
    username: API_USERNAME,
    password: API_KEY
});

type idvResponse readonly & record {
    string id;
    string idOwnerId;
    string userIdentityToken;
};

type tokenResponse readonly & record {
    string access_token;
    string token_type;
    string expires_in;
};

service asgardeo:RegistrationService on webhookListener {
    remote function onAddUser(asgardeo:AddUserEvent event) returns error? {
        string? userId = event.eventData?.userId;
        string? userName = event.eventData?.userName;
        log:printInfo(API_USERNAME);
        idvResponse idvResponse = check idvClient->/api/v1/verify/requests.post({
            // email: event.eventData.claims.hasKey("http://wso2.org/claims/emailaddress") ? event.eventData.claims["http://wso2.org/claims/emailaddress"] : "",
           // Ensure that you dont allow alphanumeric usernames.
            email: userName,
            summary: "Please verify your Identity",
            description: "To continue with your account creation please verify your identity through EvidentID",
            userAuthenticationType: "blindtrust",
            attributesRequested: [
                {"attributeType": "core.firstname"},
                {"attributeType": "core.lastname"}
            ]
        });

        oauth2:ClientOAuth2Provider provider = new({
            tokenUrl: "https://api.asgardeo.io/t/vanheim/oauth2/token",
            clientId: ASG_CLIENT_ID,
            clientSecret: ASG_CLIENT_SEC,
            scopes: ["SYSTEM"]
        });

       string token  = check provider.generateToken();

       http:Client asgardeoClient = check new ("https://api.asgardeo.io/t/vanheim", auth = {
            token: token
    });
      
      string patchUrl = "/scim2/Users/" + <string>userId;
        json|http:ClientError scim2update = asgardeoClient->patch(patchUrl, {
                "Operations": [
                    {
                        "op": "replace",
                        "value": {
                            "schemas": ["urn:scim:wso2:schema"],
                            "urn:scim:wso2:schema": {
                                "evidentRequestID": idvResponse.id,
                                "identityVerificationStatus": "PENDING"
                            }
                        }
                    }
                ]
            });

        log:printInfo((check scim2update).toString());
        }

    remote function onConfirmSelfSignup(asgardeo:GenericEvent event) returns error? {
        //Not Implemented
        log:printInfo(event.toJsonString());

    }
    remote function onAcceptUserInvite(asgardeo:GenericEvent event) returns error? {
        //Not Implemented
        log:printInfo(event.toJsonString());
    }
}

service /ignore on httpListener {
}
