<?php
// IMPORTANT: This is a temporary solution for testing only!
// In a production environment, this file should be properly secured or removed

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

// Log the request method and URI
debug_log("Request received: " . $_SERVER['REQUEST_METHOD'] . " with URI " . $_SERVER['REQUEST_URI']);

// Check if this is a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    debug_log("Method not allowed: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    exit;
}

try {
    // Get the raw input and log it
    $raw_input = file_get_contents('php://input');
    debug_log("Raw input: " . $raw_input);
    
    // Decode the JSON data
    $data = json_decode($raw_input, true);
    if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
        debug_log("JSON decode error: " . json_last_error_msg());
        throw new Exception("Invalid JSON: " . json_last_error_msg());
    }
    
    // Log received data
    debug_log("Received data: " . json_encode($data));
    
    // Check for alternative field names for compatibility with both naming conventions
    $schemeId = $data['schemeId'] ?? $data['SchemeId'] ?? null;
    $dateOfBirth = $data['dateOfBirth'] ?? null;
    $gender = $data['gender'] ?? null;
    $category = $data['category'] ?? null;
    $major = $data['major'] ?? null;
    $address = $data['address'] ?? $data['Address'] ?? null;
    $ashesiId = $data['ashesiId'] ?? $data['AshesiID'] ?? null;
    $profilePic = $data['pic'] ?? 'default_profile.jpg';
    $docReq = $data['doc'] ?? 'default_document.pdf';
    
    // Get user ID from request, default to 1 if not provided
    $user_id = $data['userId'] ?? $data['UserID'] ?? 1;
    
    // Validate required fields
    if (!$schemeId || !$dateOfBirth || !$gender || !$category || !$major || !$address || !$ashesiId) {
        debug_log("Missing required field. Available fields: " . json_encode(array_keys($data)));
        http_response_code(400);
        echo json_encode(["error" => "Missing required field(s)", "data" => $data]);
        exit;
    }
    
    // Convert date from MM/dd/yyyy to YYYY-MM-DD format for MySQL
    try {
        debug_log("Original date: " . $dateOfBirth);
        if (preg_match('/^\d{2}\/\d{2}\/\d{4}$/', $dateOfBirth)) {
            // Format is MM/DD/YYYY
            $date = DateTime::createFromFormat('m/d/Y', $dateOfBirth);
            if ($date) {
                $dateOfBirth = $date->format('Y-m-d');
                debug_log("Converted date to: " . $dateOfBirth);
            } else {
                debug_log("Failed to parse date: " . $dateOfBirth);
            }
        } else {
            debug_log("Date format doesn't match MM/DD/YYYY pattern: " . $dateOfBirth);
        }
    } catch (Exception $e) {
        debug_log("Error converting date: " . $e->getMessage());
        // Keep original date if conversion fails
    }
    
    // Create database connection
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    debug_log("Database connection established");
    
    // Generate application number - MATCH WEB VERSION FORMAT
    $application_number = mt_rand(100000000, 999999999);
    debug_log("Generated application number: " . $application_number);
    
    // Prepare the SQL statement - match column names EXACTLY as in the database
    $sql = "INSERT INTO tblapply(SchemeId, ApplicationNumber, UserID, DateofBirth, Gender, Category, Major, Address, AshesiID, ProfilePic, DocReq, Status, ApplyDate) 
            VALUES (:schemeid, :appnum, :uid, :dob, :gender, :category, :major, :address, :ashesiID, :pic, :doc, '', NOW())";
            
    debug_log("Executing SQL: " . $sql);
    debug_log("Parameters: SchemeId=" . $schemeId . ", DateofBirth=" . $dateOfBirth . 
             ", Gender=" . $gender . ", Category=" . $category . ", Major=" . $major . 
             ", Address=" . $address . ", AshesiID=" . $ashesiId);
    
    $stmt = $conn->prepare($sql);
    
    // Bind parameters with the exact column names from database
    $stmt->bindParam(':schemeid', $schemeId);
    $stmt->bindParam(':appnum', $application_number);
    $stmt->bindParam(':uid', $user_id);
    $stmt->bindParam(':dob', $dateOfBirth);
    $stmt->bindParam(':gender', $gender);
    $stmt->bindParam(':category', $category);
    $stmt->bindParam(':major', $major);
    $stmt->bindParam(':address', $address);
    $stmt->bindParam(':ashesiID', $ashesiId);
    $stmt->bindParam(':pic', $profilePic);
    $stmt->bindParam(':doc', $docReq);
    
    $stmt->execute();
    
    // Get the last inserted ID
    $last_id = $conn->lastInsertId();
    
    // Log success
    debug_log("Insert successful. ID: " . $last_id . ", Application Number: " . $application_number);
    
    // Return success response
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Your application has been sent successfully. Application Number is " . $application_number,
        "applicationId" => $last_id,
        "applicationNumber" => $application_number
    ]);
    
} catch (PDOException $e) {
    // Log database error
    debug_log("Database error: " . $e->getMessage());
    
    // Return error response
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
} catch (Exception $e) {
    // Log general error
    debug_log("Error: " . $e->getMessage());
    
    // Return error response
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Error: " . $e->getMessage()
    ]);
}
?> 