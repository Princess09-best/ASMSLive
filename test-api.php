<?php
// Allow cross-origin requests
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Simple response
echo json_encode([
    'status' => 'success',
    'message' => 'API test successful',
    'timestamp' => time(),
    'server_ip' => $_SERVER['SERVER_ADDR'],
    'client_ip' => $_SERVER['REMOTE_ADDR'],
    'request_info' => [
        'method' => $_SERVER['REQUEST_METHOD'],
        'uri' => $_SERVER['REQUEST_URI'],
        'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
    ]
]); 