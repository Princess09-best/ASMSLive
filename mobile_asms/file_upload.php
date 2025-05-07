<?php
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

// Function to log debug information
function debug_log($message) {
    file_put_contents("debug_log.txt", date("[Y-m-d H:i:s] ") . $message . "\n", FILE_APPEND);
}

// Log the request method and URI
debug_log("File Upload - Request received: " . $_SERVER['REQUEST_METHOD'] . " with URI " . $_SERVER['REQUEST_URI']);

// Check if this is a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    debug_log("Method not allowed: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    exit;
}

try {
    // Check if files were uploaded
    if (!isset($_FILES) || empty($_FILES)) {
        debug_log("No files uploaded");
        http_response_code(400);
        echo json_encode(["error" => "No files uploaded"]);
        exit;
    }

    debug_log("Processing file upload: " . json_encode($_POST));
    debug_log("Files received: " . json_encode(array_keys($_FILES)));

    // Get file type from POST data
    $fileType = $_POST['fileType'] ?? '';
    if (empty($fileType)) {
        debug_log("File type not specified");
        http_response_code(400);
        echo json_encode(["error" => "File type not specified"]);
        exit;
    }

    // Determine upload directory based on file type
    $uploadDir = '';
    $allowedExtensions = [];
    
    if ($fileType === 'profile') {
        $uploadDir = '../users/proimages/';
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        $fileField = 'profilePic';
    } elseif ($fileType === 'document') {
        $uploadDir = '../users/document/';
        $allowedExtensions = ['pdf', 'doc', 'docx'];
        $fileField = 'document';
    } else {
        debug_log("Invalid file type: $fileType");
        http_response_code(400);
        echo json_encode(["error" => "Invalid file type"]);
        exit;
    }

    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
        debug_log("Created directory: $uploadDir");
    }

    // Process the uploaded file
    if (!isset($_FILES[$fileField])) {
        debug_log("File field '$fileField' not found in request");
        http_response_code(400);
        echo json_encode(["error" => "File field '$fileField' not found in request"]);
        exit;
    }

    $file = $_FILES[$fileField];
    
    // Check for upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        debug_log("Upload error: " . $file['error']);
        http_response_code(400);
        echo json_encode(["error" => "File upload failed with error code: " . $file['error']]);
        exit;
    }

    // Get file extension
    $fileInfo = pathinfo($file['name']);
    $extension = strtolower($fileInfo['extension']);

    // Validate file extension
    if (!in_array($extension, $allowedExtensions)) {
        debug_log("Invalid file extension: $extension");
        http_response_code(400);
        echo json_encode([
            "error" => "Invalid file format. Allowed formats: " . implode(', ', $allowedExtensions)
        ]);
        exit;
    }

    // Generate a unique filename
    $filename = md5($file['name'] . time()) . time() . '.' . $extension;
    $targetPath = $uploadDir . $filename;

    // Move the uploaded file
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        debug_log("File uploaded successfully to: $targetPath");
        
        // Return success response with the filename
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "File uploaded successfully",
            "filename" => $filename,
            "path" => $targetPath
        ]);
    } else {
        debug_log("Failed to move uploaded file to: $targetPath");
        http_response_code(500);
        echo json_encode(["error" => "Failed to save the uploaded file"]);
    }

} catch (Exception $e) {
    debug_log("Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Error: " . $e->getMessage()
    ]);
}
?> 