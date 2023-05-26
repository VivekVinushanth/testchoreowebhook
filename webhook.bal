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

// string email;
// string token;

service asgardeo:RegistrationService on webhookListener {
    remote function onAddUser(asgardeo:AddUserEvent event) returns error? {
        log:printInfo(event.toJsonString());
        log:printInfo(API_USERNAME);
        idvResponse idvResponse = check idvClient->/api/v1/verify/requests.post({
            // email: event.eventData.claims.hasKey("http://wso2.org/claims/emailaddress") ? event.eventData.claims["http://wso2.org/claims/emailaddress"] : "",
            email: "cvivekvinushanth+19@gmail.com",
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
       log:printInfo(token);
       log:printInfo(idvResponse.toJsonString());


       http:Client asgardeoClient = check new ("https://api.asgardeo.io/t/vanheim", auth = {
            token: token
    });

        //  = check asgardeoClient->/scim2/Users.get({
        //     filter=username+eq+
        // });


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
