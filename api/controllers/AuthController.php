<?php
require_once __DIR__ . '/../helpers/JWTHelper.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/ValidationHelper.php';

class AuthController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        error_log("Auth Controller - Method: " . $method);
        error_log("Auth Controller - Segments: " . print_r($segments, true));
        
        $action = $segments[1] ?? '';
        error_log("Auth Controller - Action: " . $action);

        switch($method) {
            case 'POST':
                switch($action) {
                    case 'login':
                        $this->login();
                        break;
                    case 'register':
                        $this->register();
                        break;
                    case 'logout':
                        $this->logout($token);
                        break;
                    default:
                        ResponseHelper::error('Action not found', 404);
                }
                break;
            default:
                ResponseHelper::error('Method not allowed', 405);
        }
    }

    private function login() {
        error_log("Processing login request");
        $data = json_decode(file_get_contents('php://input'), true);
        error_log("Login data received: " . print_r($data, true));
        
        if (!isset($data['email']) || !isset($data['password'])) {
            ResponseHelper::error('Email and password required', 400);
            return;
        }

        try {
            $sql = "SELECT ID, FullName, Email, Password FROM tbluser WHERE Email = :email";
            $query = $this->db->prepare($sql);
            $query->bindParam(':email', $data['email']);
            $query->execute();
            $user = $query->fetch(PDO::FETCH_ASSOC);
            error_log("User query result: " . print_r($user, true));

            if ($user) {
                error_log("Stored password hash: " . $user['Password']);
                error_log("Provided password: " . $data['password']);
                
                if (password_verify($data['password'], $user['Password'])) {
                    $token = JWTHelper::generateToken($user['ID'], $user['Email']);
                    ResponseHelper::success([
                        'token' => $token,
                        'user' => [
                            'id' => $user['ID'],
                            'email' => $user['Email'],
                            'fullName' => $user['FullName']
                        ]
                    ], 'Login successful');
                    return;
                }
            }
            
            ResponseHelper::error('Invalid credentials', 401);
            
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Database error occurred', 500);
        }
    }

    private function register() {
        error_log("Processing registration request");
        $data = json_decode(file_get_contents('php://input'), true);
        $data = ValidationHelper::sanitizeInput($data);
        error_log("Registration data received: " . print_r($data, true));
        
        // Validate required fields
        $errors = ValidationHelper::validateRequired($data, ['fullName', 'email', 'password', 'mobileNumber']);
        if (!empty($errors)) {
            ResponseHelper::error('Validation failed', 400, $errors);
            return;
        }
        
        // Validate email format
        if (!ValidationHelper::validateEmail($data['email'])) {
            ResponseHelper::error('Invalid email format', 400);
            return;
        }

        try {
            // Check if email already exists
            $sql = "SELECT ID FROM tbluser WHERE Email = :email";
            $query = $this->db->prepare($sql);
            $query->bindParam(':email', $data['email']);
            $query->execute();
            
            if ($query->fetch()) {
                ResponseHelper::error('Email already registered', 400);
                return;
            }

            // Hash password
            $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);

            // Insert new user
            $sql = "INSERT INTO tbluser (FullName, Email, MobileNumber, Password) 
                    VALUES (:fullName, :email, :mobileNumber, :password)";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':fullName', $data['fullName']);
            $query->bindParam(':email', $data['email']);
            $query->bindParam(':mobileNumber', $data['mobileNumber']);
            $query->bindParam(':password', $hashedPassword);
            
            $query->execute();
            $userId = $this->db->lastInsertId();
            
            // Generate token for immediate login after registration
            $token = JWTHelper::generateToken($userId, $data['email']);
            
            ResponseHelper::success([
                'token' => $token,
                'user' => [
                    'id' => $userId,
                    'email' => $data['email'],
                    'fullName' => $data['fullName']
                ]
            ], 'Registration successful');
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Registration failed: ' . $e->getMessage(), 500);
        }
    }
    
    private function logout($token) {
        
        if ($token) {
            
            $userData = JWTHelper::validateToken($token);
            if ($userData) {
                
                error_log("User ID {$userData['userId']} logged out");
            }
        }
        
        ResponseHelper::success(null, 'Logout successful');
    }
} 