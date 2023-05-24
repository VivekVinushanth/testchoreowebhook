import ballerinax/trigger.asgardeo;
import ballerina/log;
import ballerina/http;

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

service asgardeo:RegistrationService on webhookListener {
    remote function onAddUser(asgardeo:AddUserEvent event) returns error? {
        log:printInfo(event.toJsonString());
        log:printInfo(API_USERNAME);
        idvResponse idvResponse = check idvClient->/api/v1/verify/requests.post({
            email: "cvivekvinushanth+1@gmail.com",
            summary: "Please verify your Identity",
            description: "To continue with your account creation please verify your identity through EvidentID",
            userAuthenticationType: "blindtrust",
            attributesRequested: [
                {"attributeType": "core.firstname"},
                {"attributeType": "core.lastname"}
            ]
        });
        log:printInfo(idvResponse.toJsonString());

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
