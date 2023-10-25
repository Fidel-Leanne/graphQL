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

    resource function post employeeTotalScores(int departmentId) returns EmployeeScore[]|error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        // Parameterized query to fetch the total scores of employees in the department
        sql:ParameterizedQuery selectQuery = `
        SELECT u.user_id AS employeeId, u.name, SUM(pe.score * k.weight / 100) AS totalScore
        FROM Users u
        JOIN PerformanceEvaluations pe ON u.user_id = pe.employee_id
        JOIN KPIs k ON pe.kpi_id = k.kpi_id
        WHERE u.department_id = ?
        GROUP BY u.user_id, u.name`;

        var queryResult = dbClient->query(selectQuery, [departmentId]);

        // Always close the database connection
        check dbClient.close();

        if queryResult is stream<EmployeeScore, sql:Error> {
            EmployeeScore[] employeeScores = [];
            _ = queryResult.forEach(function(EmployeeScore es) {
                employeeScores.push(es);
            });
            return employeeScores;
        } else if queryResult is sql:Error {
            return error("Error occurred while fetching the total scores of employees: " + queryResult.message());
        } else {
            return error("Unknown error occurred.");
        }
    }

    resource function post deleteEmployeeKPI(int kpiId) returns boolean|Error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        sql:ParameterizedQuery deleteQuery = `DELETE FROM KPIs WHERE kpi_id = ${kpiId}`;

        var result = dbClient->execute(deleteQuery);

        // Make sure to close the database connection
        check dbClient.close();

        if result is sql:ExecutionResult {
            // If affectedRowCount is more than 0, it means the deletion was successful
            if result.affectedRowCount > 0 {
                return true;
            } else {
                return false; // Could not find a record with the provided kpiId
            }
        } else {
            return {message: "Error occurred while deleting the KPI from the database"};
        }
    }

    resource function post gradeEmployeeKPI(int kpiId, float score) returns boolean|Error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        // SQL query to update the score for the given kpiId
        sql:ParameterizedQuery updateQuery = `UPDATE PerformanceEvaluations SET score = ${score} WHERE kpi_id = ${kpiId}`;

        var result = dbClient->execute(updateQuery);

        // Always close the database connection
        check dbClient.close();

        if result is sql:ExecutionResult {
            // If affectedRowCount is more than 0, it means the update was successful
            if result.affectedRowCount > 0 {
                return true;
            } else {
                return false; // Could not find a record with the provided kpiId or no updates were made
            }
        } else {
            return {message: "Error occurred while grading the KPI in the database."};
        }
    };

    resource function post specificEmployeeScores(int employeeId) returns EmployeeScore|error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        sql:ParameterizedQuery selectQuery = `
        SELECT u.user_id AS employeeId, u.name, SUM(pe.score * k.weight / 100) AS totalScore
        FROM Users u
        JOIN PerformanceEvaluations pe ON u.user_id = pe.employee_id
        JOIN KPIs k ON pe.kpi_id = k.kpi_id
        WHERE u.user_id = ?
        GROUP BY u.user_id, u.name`;

        var queryResult = dbClient->query(selectQuery, [employeeId]);

        // Always close the database connection
        check dbClient.close();

        if queryResult is stream<EmployeeScore, sql:Error> {
            EmployeeScore? empScore = ();
            _ = queryResult.forEach(function(EmployeeScore es) {
                empScore = es;
            });

            if empScore is EmployeeScore {
                return empScore;
            } else {
                return error("Error retrieving or no score data for the given employee ID.");
            }
        } else if queryResult is sql:Error {
            return error("Error occurred while fetching the employee's scores from the database: " + queryResult.message());
        } else {
            return error("Unknown error occurred.");
        }
    }

    resource function post createEmployeeKPI(string name, string? description = (),floatweight,string?unitOfMeasurement=()) returns KPI|Error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        sql:ParameterizedQuery insertQuery = `INSERT INTO KPIs(kpi_name, description, weight, unit_of_measurement) VALUES (?, ?, ?, ?)`;
        var result = dbClient->execute(insertQuery);

        if result is sql:ExecutionResult {
            string|int? insertedId = result.lastInsertId;

            if insertedId is int {
                // Use parameterized query for SELECT
                sql:ParameterizedQuery selectQuery = `SELECT * FROM KPIs WHERE kpi_id = ?`;
                var selectResult = dbClient->query(selectQuery, [insertedId]);

                // Close the database connection early
                var closeResult = dbClient.close();
                if closeResult is sql:Error {
                    return {message: "Error occurred while closing the database connection."};
                }

                if selectResult is stream<KPI, sql:Error> {
                    KPI? newKPI = ();
                    _ = selectResult.forEach(function(KPI kpi) {
                        newKPI = kpi;
                    });

                    if newKPI is KPI {
                        return newKPI;
                    } else {
                        return {message: "Error retrieving the newly created KPI."};
                    }
                } else {
                    return {message: "Error retrieving the newly created KPI."};
                }
            } else {
                return {message: "Failed to retrieve the inserted KPI's ID."};
            }
        } else {
            // Ensure you close the database connection
            check dbClient.close();
            return {message: "Error occurred while inserting the KPI into the database."};
        }
    }

    resource function post gradeSupervisor(float score) returns SupervisorGrade?|error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        int supervisor_id = 1; // TODO: Adjust according to your context

        sql:ParameterizedQuery insertQuery = `INSERT INTO SupervisorGrades(supervisor_id, score) VALUES (?, ?)`;
        var result = dbClient->execute(insertQuery);

        if result is sql:ExecutionResult {
            string|int? insertedId = result.lastInsertId;

            if insertedId is int {
                sql:ParameterizedQuery selectQuery = `SELECT * FROM SupervisorGrades WHERE grade_id = ?`;
                var selectResult = dbClient->queryRow<SupervisorGrade>(selectQuery);

                if selectResult is stream<SupervisorGrade, sql:Error> {
                    SupervisorGrade? newGrade = ();
                    _ = selectResult.forEach(function(SupervisorGrade grade) {
                        newGrade = grade;
                    });

                    if newGrade is SupervisorGrade {
                        return newGrade;
                    } else {
                        return error("Error retrieving the newly created grade.");
                    }
                } else if selectResult is sql:Error {
                    return error("Error occurred while fetching the supervisor's grade from the database: ");
                } else {
                    return error("Unknown error occurred while fetching the grade.");
                }
            } else {
                return error("Failed to retrieve the inserted grade's ID.");
            }
        } else if result is sql:Error {
            return error("Error occurred while grading the supervisor in the database: " + result.message());
        } else {
            return error("Unknown error occurred while grading.");
        }

        // Ensure you close the database connection in all exit paths
        check dbClient.close();

    }

    resource function post viewEmployeeScores() returns EmployeeScore|Error {

        mysql:Client dbClient = check new (host = "localhost", user = "root", password = "btsxarmy8", database = "graphQL");

        int authenticatedUserId = getAuthenticatedUserId();

        sql:ParameterizedQuery selectQuery = `
    SELECT u.user_id AS employeeId, u.name, SUM(pe.score * k.weight / 100) AS totalScore
    FROM Users u
    JOIN PerformanceEvaluations pe ON u.user_id = pe.employee_id
    JOIN KPIs k ON pe.kpi_id = k.kpi_id
    WHERE u.user_id = ?
    GROUP BY u.user_id, u.name`;

        var queryResult = dbClient->query(selectQuery, [authenticatedUserId]);

        if queryResult is stream<EmployeeScore, sql:Error> {
            EmployeeScore? empScore = ();
            _ = queryResult.forEach(function(EmployeeScore es) {
                empScore = es;
            });

            // Close the database connection
            var closeResult = dbClient.close();
            if closeResult is sql:Error {
                return {message: "Error occurred while closing the database connection."};
            }

            if empScore is EmployeeScore {
                return empScore;
            } else {
                return {message: "Error retrieving or no score data for the authenticated employee."};
            }
        }
        else if queryResult is sql:Error {
            return {};
        }

        return {message: "Unexpected error occurred while retrieving the employee score."};
    }

}

function getAuthenticatedUserId() returns int {
    return 0;
}

