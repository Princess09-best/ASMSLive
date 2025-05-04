<?php
require_once 'helpers/JWTHelper.php';

class ApplicationController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        // Verify token for all application endpoints
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            return;
        }

        $id = $segments[1] ?? null;
        
        switch($method) {
            case 'GET':
                if ($id) {
                    if ($segments[2] === 'status') {
                        $this->getApplicationStatus($id, $token);
                    } else {
                        $this->getApplication($id, $token);
                    }
                } else {
                    $this->listApplications($token);
                }
                break;
            case 'POST':
                $this->createApplication($token);
                break;
            case 'PUT':
                if ($id) {
                    $this->updateApplication($id, $token);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Application ID required']);
                }
                break;
            default:
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
        }
    }

    private function listApplications($token) {
        try {
            $userData = JWTHelper::validateToken($token);
            $userId = $userData['userId'];

            $sql = "SELECT a.*, s.SchemeName 
                    FROM tblapply a 
                    JOIN tblscheme s ON a.SchemeId = s.ID 
                    WHERE a.UserID = :userId 
                    ORDER BY a.ApplyDate DESC";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $applications = $query->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['applications' => $applications]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch applications']);
        }
    }

    private function getApplication($id, $token) {
        try {
            $userData = JWTHelper::validateToken($token);
            $userId = $userData['userId'];

            $sql = "SELECT a.*, s.* 
                    FROM tblapply a 
                    JOIN tblscheme s ON a.SchemeId = s.ID 
                    WHERE a.ID = :id AND a.UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $application = $query->fetch(PDO::FETCH_ASSOC);
            
            if ($application) {
                echo json_encode(['application' => $application]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Application not found']);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch application']);
        }
    }

    private function createApplication($token) {
        try {
            $userData = JWTHelper::validateToken($token);
            $userId = $userData['userId'];
            
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Validate required fields
            $required = ['schemeId', 'dateOfBirth', 'gender', 'category', 'major', 'address', 'ashesiId'];
            foreach ($required as $field) {
                if (!isset($data[$field])) {
                    http_response_code(400);
                    echo json_encode(['error' => "Missing required field: $field"]);
                    return;
                }
            }

            // Check if already applied
            $sql = "SELECT ID FROM tblapply WHERE UserID = :userId AND SchemeId = :schemeId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->bindParam(':schemeId', $data['schemeId']);
            $query->execute();
            
            if ($query->fetch()) {
                http_response_code(400);
                echo json_encode(['error' => 'Already applied for this scholarship']);
                return;
            }

            // Generate application number
            $applicationNumber = 'APP' . time() . rand(100, 999);

            // Create application
            $sql = "INSERT INTO tblapply (UserID, SchemeId, ApplicationNumber, DateofBirth, 
                    Gender, Category, Major, Address, AshesiID, Status, ApplyDate) 
                    VALUES (:userId, :schemeId, :applicationNumber, :dateOfBirth, 
                    :gender, :category, :major, :address, :ashesiId, '0', NOW())";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->bindParam(':schemeId', $data['schemeId']);
            $query->bindParam(':applicationNumber', $applicationNumber);
            $query->bindParam(':dateOfBirth', $data['dateOfBirth']);
            $query->bindParam(':gender', $data['gender']);
            $query->bindParam(':category', $data['category']);
            $query->bindParam(':major', $data['major']);
            $query->bindParam(':address', $data['address']);
            $query->bindParam(':ashesiId', $data['ashesiId']);
            
            $query->execute();
            
            echo json_encode([
                'message' => 'Application submitted successfully',
                'applicationId' => $this->db->lastInsertId(),
                'applicationNumber' => $applicationNumber
            ]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to create application']);
        }
    }

    private function getApplicationStatus($id, $token) {
        try {
            $userData = JWTHelper::validateToken($token);
            $userId = $userData['userId'];

            $sql = "SELECT ID, ApplicationNumber, Status, Remark, ApplyDate, UpdationDate 
                    FROM tblapply 
                    WHERE ID = :id AND UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $status = $query->fetch(PDO::FETCH_ASSOC);
            
            if ($status) {
                echo json_encode(['status' => $status]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Application not found']);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch application status']);
        }
    }
} 