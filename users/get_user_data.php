<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Include database connection
include('includes/dbconnect.php');

// Headers to allow the mobile app to access this endpoint
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

// Check if username is provided
if(isset($_POST['username'])) {
    $username = $_POST['username'];
    
    try {
        // Query to fetch user data
        $sql = "SELECT ID, FullName, Email, MobileNumber FROM tbluser WHERE UserName = :username";
        $query = $db->prepare($sql);
        $query->bindParam(':username', $username, PDO::PARAM_STR);
        $query->execute();
        
        // Check if user exists
        if($query->rowCount() > 0) {
            $userData = $query->fetch(PDO::FETCH_ASSOC);
            
            // Format response
            $response = [
                'success' => true,
                'id' => (int)$userData['ID'],
                'fullName' => $userData['FullName'],
                'email' => $userData['Email'],
                'mobileNumber' => $userData['MobileNumber'],
                'message' => 'User data retrieved successfully'
            ];
            
            echo json_encode($response);
        } else {
            // User not found
            echo json_encode([
                'success' => false,
                'message' => 'User not found'
            ]);
        }
    } catch(PDOException $e) {
        // Database error
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
} else {
    // Missing username parameter
    echo json_encode([
        'success' => false,
        'message' => 'Username parameter is required'
    ]);
}
?> 