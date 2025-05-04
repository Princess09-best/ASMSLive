<?php
require_once 'helpers/JWTHelper.php';
require_once 'helpers/ResponseHelper.php';
require_once 'helpers/ValidationHelper.php';

class UserController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        // Verify token for all user endpoints
        if (!$token) {
            ResponseHelper::error('Authentication required', 401);
            return;
        }

        $userData = JWTHelper::validateToken($token);
        if (!$userData) {
            ResponseHelper::error('Invalid token', 401);
            return;
        }

        $action = $segments[1] ?? '';
        
        switch($method) {
            case 'GET':
                if ($action === 'profile') {
                    $this->getProfile($userData['userId']);
                } else {
                    ResponseHelper::error('Action not found', 404);
                }
                break;
            case 'PUT':
                if ($action === 'profile') {
                    $this->updateProfile($userData['userId']);
                } else if ($action === 'password') {
                    $this->changePassword($userData['userId']);
                } else {
                    ResponseHelper::error('Action not found', 404);
                }
                break;
            default:
                ResponseHelper::error('Method not allowed', 405);
        }
    }

    private function getProfile($userId) {
        try {
            $sql = "SELECT ID, FullName, Email, MobileNumber, RegDate 
                    FROM tbluser WHERE ID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $profile = $query->fetch(PDO::FETCH_ASSOC);
            
            if ($profile) {
                // Remove sensitive fields
                unset($profile['Password']);
                ResponseHelper::success(['profile' => $profile]);
            } else {
                ResponseHelper::error('User not found', 404);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Failed to fetch user profile', 500);
        }
    }

    private function updateProfile($userId) {
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            $data = ValidationHelper::sanitizeInput($data);
            
            // Validate required fields
            $errors = ValidationHelper::validateRequired($data, ['fullName', 'mobileNumber']);
            if (!empty($errors)) {
                ResponseHelper::error('Validation failed', 400, $errors);
                return;
            }

            // Update profile
            $sql = "UPDATE tbluser SET 
                    FullName = :fullName, 
                    MobileNumber = :mobileNumber 
                    WHERE ID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':fullName', $data['fullName']);
            $query->bindParam(':mobileNumber', $data['mobileNumber']);
            $query->bindParam(':userId', $userId);
            $query->execute();
            
            ResponseHelper::success(null, 'Profile updated successfully');
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Failed to update profile', 500);
        }
    }

    private function changePassword($userId) {
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Validate required fields
            $errors = ValidationHelper::validateRequired($data, ['currentPassword', 'newPassword']);
            if (!empty($errors)) {
                ResponseHelper::error('Validation failed', 400, $errors);
                return;
            }

            // Verify current password
            $sql = "SELECT Password FROM tbluser WHERE ID = :userId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $user = $query->fetch(PDO::FETCH_ASSOC);
            
            if (!$user || !password_verify($data['currentPassword'], $user['Password'])) {
                ResponseHelper::error('Current password is incorrect', 400);
                return;
            }

            // Validate new password length
            if (!ValidationHelper::validateLength($data['newPassword'], 6, 20)) {
                ResponseHelper::error('New password must be between 6 and 20 characters', 400);
                return;
            }

            // Update password
            $hashedPassword = password_hash($data['newPassword'], PASSWORD_DEFAULT);
            $sql = "UPDATE tbluser SET Password = :password WHERE ID = :userId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':password', $hashedPassword);
            $query->bindParam(':userId', $userId);
            $query->execute();
            
            ResponseHelper::success(null, 'Password changed successfully');
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Failed to change password', 500);
        }
    }
} 