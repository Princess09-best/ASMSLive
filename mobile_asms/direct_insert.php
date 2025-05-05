<?php
// IMPORTANT: This is a temporary solution for testing only!
// In a production environment, this file should be properly secured or removed

// Set CORS headers to allow requests from your mobile app
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Database connection parameters
$host = "localhost";
$db_name = "webtech_fall2024_princess_balogun";
$username = "root";
$password = "";

// Function to log debug information
function debug_log($message) {
    file_put_contents("debug_log.txt", date("[Y-m-d H:i:s] ") . $message . "\n", FILE_APPEND);
}

// Check if this is a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    exit;
}

try {
    // Get the JSON data from the request
    $json_data = file_get_contents('php://input');
    $data = json_decode($json_data, true);
    
    // Log received data
    debug_log("Received data: " . $json_data);
    
    // Validate required fields
    $required_fields = ['scholarshipId', 'dateOfBirth', 'gender', 'category', 'major', 'homeAddress', 'studentId'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode(["error" => "Missing required field: " . $field]);
            exit;
        }
    }
    
    // Create database connection
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Generate application number
    $application_number = 'APP' . time() . rand(100, 999);
    
    // Default user ID for testing (in production, this would come from authentication)
    $user_id = 1;
    
    // Insert application into database
    $stmt = $conn->prepare("
        INSERT INTO tblapply (
            UserID, SchemeId, ApplicationNumber, DateofBirth, Gender, 
            Category, Major, Address, AshesiID, Status, ApplyDate
        ) VALUES (
            :userId, :schemeId, :applicationNumber, :dateOfBirth, :gender,
            :category, :major, :address, :ashesiId, '0', NOW()
        )
    ");
    
    $stmt->bindParam(':userId', $user_id);
    $stmt->bindParam(':schemeId', $data['scholarshipId']);
    $stmt->bindParam(':applicationNumber', $application_number);
    $stmt->bindParam(':dateOfBirth', $data['dateOfBirth']);
    $stmt->bindParam(':gender', $data['gender']);
    $stmt->bindParam(':category', $data['category']);
    $stmt->bindParam(':major', $data['major']);
    $stmt->bindParam(':address', $data['homeAddress']);
    $stmt->bindParam(':ashesiId', $data['studentId']);
    
    $stmt->execute();
    
    // Get the last inserted ID
    $last_id = $conn->lastInsertId();
    
    // Log success
    debug_log("Insert successful. ID: " . $last_id);
    
    // Return success response
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Application submitted successfully",
        "applicationId" => $last_id,
        "applicationNumber" => $application_number
    ]);
    
} catch (PDOException $e) {
    // Log error
    debug_log("Database error: " . $e->getMessage());
    
    // Return error response
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
} catch (Exception $e) {
    // Log error
    debug_log("Error: " . $e->getMessage());
    
    // Return error response
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Error: " . $e->getMessage()
    ]);
}
?> 