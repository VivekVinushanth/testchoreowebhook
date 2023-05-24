import ballerina/os;

public function getFromEnvVariable(string envVaribale, string defaultValue) returns string {
    string envVariableVal = os:getEnv(envVaribale);
    string valueToSet = envVariableVal != "" ? envVariableVal : defaultValue;
    return valueToSet;
}

public configurable string API_KEY = getFromEnvVariable("api-key", "password");
public configurable string API_USERNAME = getFromEnvVariable("api-username", "username");