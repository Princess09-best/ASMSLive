<?php
// Test script for direct_insert.php
echo "Testing direct_insert.php...\n";

// Sample data
$data = array(
    'scholarshipId' => 5,
    'dateOfBirth' => '05/05/2000',
    'gender' => 'Male',
    'category' => 'Regular',
    'major' => 'Computer Science',
    'homeAddress' => '123 Test Street',
    'studentId' => '12345678'
);

// Convert to JSON
$json_data = json_encode($data);
echo "Sending data: $json_data\n";

// Initialize cURL session
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, 'http://localhost/ASMSLive/direct_insert.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Content-Length: ' . strlen($json_data)
));

// Execute cURL session
echo "Sending request...\n";
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

// Check for errors
if(curl_errno($ch)) {
    echo "cURL Error: " . curl_error($ch) . "\n";
} else {
    echo "HTTP Status Code: $http_code\n";
    echo "Response: $response\n";
}

// Close cURL session
curl_close($ch);

echo "Test completed.\n";
?> 