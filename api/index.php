<?php
header('Content-Type: application/json');
require_once('../includes/dbconnect.php');

// Enable CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, GET, DELETE, PUT, PATCH, OPTIONS');
    header('Access-Control-Allow-Headers: Authorization, Content-Type');
    header('Access-Control-Max-Age: 1728000');
    header('Content-Length: 0');
    header('Content-Type: text/plain');
    die();
}

header('Access-Control-Allow-Origin: *');

// Get the request method and path
$method = $_SERVER['REQUEST_METHOD'];

// Parse the URL path
$request_uri = $_SERVER['REQUEST_URI'];
$base_path = '/ASMSLive/api/';
$path = parse_url($request_uri, PHP_URL_PATH);
$path = substr($path, strpos($path, $base_path) + strlen($base_path));
$segments = explode('/', trim($path, '/'));
$resource = $segments[0] ?? '';

// Check for API versioning
$version = "";
if (isset($_GET['version'])) {
    $version = $_GET['version'] . "/";
    error_log("API Version: " . $version);
}

// Debug information
error_log("Request URI: " . $request_uri);
error_log("Path: " . $path);
error_log("Resource: " . $resource);

// Get JWT token from header
$headers = getallheaders();
$auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';
$token = str_replace('Bearer ', '', $auth_header);

// Include the appropriate controller based on the resource
switch($resource) {
    case 'auth':
        require_once __DIR__ . '/controllers/AuthController.php';
        $controller = new AuthController($db);
        break;
    case 'scholarships':
        require_once __DIR__ . '/controllers/ScholarshipController.php';
        $controller = new ScholarshipController($db);
        break;
    case 'applications':
        require_once __DIR__ . '/controllers/ApplicationController.php';
        $controller = new ApplicationController($db);
        break;
    case 'documents':
        require_once __DIR__ . '/controllers/DocumentController.php';
        $controller = new DocumentController($db);
        break;
    case 'users':
        require_once __DIR__ . '/controllers/UserController.php';
        $controller = new UserController($db);
        break;
    case 'notifications':
        require_once __DIR__ . '/controllers/NotificationController.php';
        $controller = new NotificationController($db);
        break;
        case 'bank-details':
            require_once __DIR__ . '/controllers/BankDetailsController.php';
            $controller = new BankDetailsController($db);
            break;
    default:
        http_response_code(404);
        echo json_encode([
            'error' => 'Resource not found',
            'resource' => $resource,
            'path' => $path,
            'segments' => $segments
        ]);
        exit();
}

// Handle the request
try {
    $controller->handleRequest($method, $segments, $token);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
} 