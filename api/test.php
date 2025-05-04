<?php
// Test script for API endpoints
header('Content-Type: text/plain');

function testEndpoint($method, $endpoint, $data = null) {
    $url = "http://localhost/ASMSLive/api/" . $endpoint;
    $ch = curl_init($url);
    
    $headers = ['Content-Type: application/json'];
    if (isset($GLOBALS['token'])) {
        $headers[] = 'Authorization: Bearer ' . $GLOBALS['token'];
    }
    
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    if ($data) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'status' => $httpCode,
        'response' => json_decode($response, true)
    ];
}

echo "Testing API endpoints...\n\n";

// Test 1: Register a new user
echo "1. Testing Registration:\n";
$registerData = [
    'fullName' => 'Test User New',
    'email' => 'testnew@ashesi.edu.gh',
    'password' => 'TestPass123!',
    'mobileNumber' => '0555123456'
];
$result = testEndpoint('POST', 'auth/register', $registerData);
echo "Status: " . $result['status'] . "\n";
echo "Response: "; print_r($result['response']); echo "\n\n";

// Test 2: Login with existing credentials
echo "2. Testing Login:\n";
$loginData = [
    'email' => 'testnew@ashesi.edu.gh',
    'password' => 'TestPass123!'
];
$result = testEndpoint('POST', 'auth/login', $loginData);
echo "Status: " . $result['status'] . "\n";
echo "Response: "; print_r($result['response']); echo "\n\n";

if (isset($result['response']['token'])) {
    $GLOBALS['token'] = $result['response']['token'];
    
    // Test 3: Get specific scholarship
    echo "3. Testing Get Scholarship Details:\n";
    $result = testEndpoint('GET', 'scholarships/2');
    echo "Status: " . $result['status'] . "\n";
    echo "Response: "; print_r($result['response']); echo "\n\n";

    // Test 4: Submit application
    echo "4. Testing Submit Application:\n";
    $applicationData = [
        'schemeId' => 2,
        'dateOfBirth' => '2000-01-01',
        'gender' => 'Female',
        'category' => 'Regular',
        'major' => 'Computer Science',
        'address' => 'Ashesi University',
        'ashesiId' => '12345678'
    ];
    $result = testEndpoint('POST', 'applications', $applicationData);
    echo "Status: " . $result['status'] . "\n";
    echo "Response: "; print_r($result['response']); echo "\n\n";

    if (isset($result['response']['applicationId'])) {
        $applicationId = $result['response']['applicationId'];

        // Test 5: Get application status
        echo "5. Testing Get Application Status:\n";
        $result = testEndpoint('GET', "applications/$applicationId/status");
        echo "Status: " . $result['status'] . "\n";
        echo "Response: "; print_r($result['response']); echo "\n\n";

        // Test 6: List all applications
        echo "6. Testing List Applications:\n";
        $result = testEndpoint('GET', 'applications');
        echo "Status: " . $result['status'] . "\n";
        echo "Response: "; print_r($result['response']); echo "\n\n";
    }
}

echo "API Testing Complete!\n"; 