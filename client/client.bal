import ballerina/io;
import ballerina/http;

http:Client graphqlClient = check new ("http://localhost:4000/graphql");

public function main() {
    // Prompt the user for input to determine the action
    string userInput;
    io:println("Select an option:");
    io:println("1: Fetch employee scores");
    io:println("2: Grade supervisor");
    // ... add more options

    string input = check io:readln("Enter your choice: ");
    if (input == "1") {
        fetchEmployeeScores();
    } else if (input == "2") {
        gradeSupervisor();
    }
    // ... handle other inputs
}

function fetchEmployeeScores() {
    string payload = string `{ "query": "your graphql query to fetch employee scores" }`;
    var response = graphqlClient->post("/", payload);
    io:println(response);
    // Handle response, errors, etc.
}

function gradeSupervisor() {
    // You would collect more input from the user here, like the grade value, and include it in your mutation
    string payload = string `{ "query": "your graphql mutation to grade a supervisor" }`;
    var response = graphqlClient->post("/", payload);
    io:println(response);
    // Handle response, errors, etc.
}
