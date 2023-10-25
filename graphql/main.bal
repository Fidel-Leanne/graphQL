import ballerina/graphql;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string USER = "root";
configurable string PASSWORD = "btsxarmy";
configurable string HOST = "localhost";
configurable int PORT = 3306;
configurable string DATABASE = "graphQL";

type Error record {|

    string message;
|};

// Users Record
public type User record {
    int user_id?;
    string name;
    string email;
    string role;
    int? department_id;
};

// Departments Record
public type Department record {
    int department_id?;
    string department_name;
    int? head_of_department;
};

// Objectives Record
public type Objective record {
    int department_id;
    string objective_name;
    string description;
    float weight;
    int objective_id;
};

// KPIs Record
public type KPI record {
    int kpi_id?;
    int employee_id;
    string kpi_name;
    string description?;
    decimal weight;
    string? unit_of_measurement;
};

public distinct service class UserService {
}

type EmployeeScore record {|

|};

type floatweight record {

};

type SupervisorGrade record {|

|};

service /graphql on new graphql:Listener(4000) {

    resource function get createDepartmentObjective(int departmentId, string name, string description, float weight) returns Objective|Error|error {
        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        string insertQuery = "INSERT INTO Objectives(department_id, objective_name, description, weight) VALUES (?, ?, ?, ?)";
        sql:ParameterizedQuery query = `INSERT INTO Objectives(department_id, objective_name, description, weight) VALUES (${departmentId}, ${name}, ${description}, ${weight})`;

        var result = dbClient->execute(query);

        if result is sql:ExecutionResult {
            // Get the last inserted ID
            string|int? insertedId = result.lastInsertId;
            if insertedId is int {
                return {
                department_id: departmentId,
                objective_name: name,
                description: description,
                weight: weight,
                objective_id: insertedId
            };
            } else {
                return {message: "Failed to retrieve the inserted objective's ID"};
            }
        } else {
            return {message: "Error occurred while inserting the objective into the database"};
        }

    }

    resource function get deleteDepartmentObjective(int objectiveId) returns boolean|Error|error {
        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        sql:ParameterizedQuery deleteQuery = `DELETE FROM Objectives WHERE objective_id = ?`;

        var result = dbClient->execute(deleteQuery);

        // Make sure to close the database connection!
        check dbClient.close();

        if result is sql:ExecutionResult {
            // If affectedRowCount is more than 0, it means the deletion was successful
            if result.affectedRowCount > 0 {
                return true;
            } else {
                return false; // Could not find a record with the provided objectiveId
            }
        } else {
            return {message: "Error occurred while deleting the objective from the database"};
        }
    }

    resource function get assignEmployeeToSupervisor(int employeeId, int supervisorId) returns boolean|Error|error {
        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        sql:ParameterizedQuery updateQuery = `UPDATE Users SET supervisor_id = ${supervisorId} WHERE user_id = ${employeeId}`;

        var result = dbClient->execute(updateQuery);

        // Always close the database connection
        check dbClient.close();

        if result is sql:ExecutionResult {
            // If affectedRowCount is more than 0, it means the update was successful
            if result.affectedRowCount > 0 {
                return true;
            } else {
                return false; // Could not find a user with the provided employeeId
            }
        } else {
            return {message: "Error occurred while assigning the employee to the supervisor"};
        }
    }

}
