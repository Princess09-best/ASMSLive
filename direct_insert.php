<?php
// IMPORTANT: This is a temporary solution for testing only!
// In a production environment, this file should be properly secured

// Log all incoming requests immediately
file_put_contents("debug_log.txt", date("[Y-m-d H:i:s] ") . "Request received: " . $_SERVER['REQUEST_METHOD'] . " with URI " . $_SERVER['REQUEST_URI'] . "\n", FILE_APPEND);

// Set CORS headers to allow requests from your mobile app
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Database connection parameters
$host = "localhost";
$db_name = "webtech_fall2024_princess_balogun";
$username = "root";
$password = "";

// Function to log debug information
function debug_log($message) {
    file_put_contents("debug_log.txt", date("[Y-m-d H:i:s] ") . $message . "\n", FILE_APPEND);
}

// Log all requests for debugging
debug_log("Request received: " . $_SERVER['REQUEST_METHOD']);

// Check if this is a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    debug_log("Method not allowed: " . $_SERVER['REQUEST_METHOD']);
    exit;
}

try {
    // Get the JSON data from the request
    $json_data = file_get_contents('php://input');
    debug_log("Raw input: " . $json_data);
    
    $data = json_decode($json_data, true);
    if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
        debug_log("JSON decode error: " . json_last_error_msg());
        http_response_code(400);
        echo json_encode(["error" => "Invalid JSON: " . json_last_error_msg()]);
        exit;
    }
    
    // Log received data
    debug_log("Received data: " . json_encode($data));
    
    // Validate required fields
    $required_fields = ['scholarshipId', 'dateOfBirth', 'gender', 'category', 'major', 'homeAddress', 'studentId'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode(["error" => "Missing required field: " . $field]);
            debug_log("Missing required field: " . $field);
            exit;
        }
    }
    
    // Create database connection
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    debug_log("Database connection established");
    
    // Generate application number - matches the web interface
    $appnum = mt_rand(100000000, 999999999);
    
    // Default user ID for testing (in production, this would come from authentication)
    $user_id = 1;
    
    // Check if already applied - matches the web interface
    $check_sql = "SELECT ID FROM tblapply WHERE UserID = :uid AND SchemeId = :schemeid";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bindParam(':uid', $user_id);
    $check_stmt->bindParam(':schemeid', $data['scholarshipId']);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(["error" => "Already applied for this scholarship"]);
        debug_log("Already applied for scholarship ID: " . $data['scholarshipId']);
        exit;
    }
    
    // Default file names for pictures/documents - would be properly handled in the full implementation
    $pic_filename = "mobile_default_pic.jpg";
    $doc_filename = "mobile_default_doc.pdf";
    
    // Insert application into database - EXACT MATCH to web interface SQL
    $sql = "INSERT INTO tblapply(SchemeId, ApplicationNumber, UserID, DateofBirth, Gender, Category, Major, Address, AshesiID, ProfilePic, DocReq) 
            VALUES (:schemeid, :appnum, :uid, :dob, :gender, :category, :major, :address, :ashesiID, :pic, :doc)";
    
    debug_log("Executing SQL: " . $sql);
    
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':schemeid', $data['scholarshipId']);
    $stmt->bindParam(':appnum', $appnum);
    $stmt->bindParam(':uid', $user_id);
    $stmt->bindParam(':dob', $data['dateOfBirth']);
    $stmt->bindParam(':gender', $data['gender']);
    $stmt->bindParam(':category', $data['category']);
    $stmt->bindParam(':major', $data['major']);
    $stmt->bindParam(':address', $data['homeAddress']);
    $stmt->bindParam(':ashesiID', $data['studentId']);
    $stmt->bindParam(':pic', $pic_filename);
    $stmt->bindParam(':doc', $doc_filename);
    
    $stmt->execute();
    
    // Get the last inserted ID
    $last_id = $conn->lastInsertId();
    
    // Log success
    debug_log("Insert successful. ID: " . $last_id . ", Application Number: " . $appnum);
    
    // Return success response
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Your application has been sent successfully. Application Number is " . $appnum,
        "applicationId" => $last_id,
        "applicationNumber" => $appnum
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