<?php
require_once 'helpers/JWTHelper.php';

class ApplicationController {
    private $db;
    private $uploadDir;

    public function __construct($db) {
        $this->db = $db;
        // Set upload directories for profile pics and documents
        $this->uploadDir = [
            'profile' => '../uploads/profile_pictures/',
            'document' => '../uploads/documents/'
        ];
        
        // Create the upload directories if they don't exist
        foreach ($this->uploadDir as $dir) {
            if (!file_exists($dir)) {
                mkdir($dir, 0777, true);
            }
        }
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
            
            // Determine if the request is multipart/form-data or JSON
            $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
            $isMultipart = strpos($contentType, 'multipart/form-data') !== false;
            
            if ($isMultipart) {
                // Handle form data with file uploads
                $data = $_POST;
                $hasFiles = isset($_FILES['passportPhoto']) && isset($_FILES['document']);
            } else {
                // Handle JSON data (API call from mobile app)
                $data = json_decode(file_get_contents('php://input'), true);
                $hasFiles = false;
            }
            
            // Log request data for debugging
            error_log("Application submission - isMultipart: " . ($isMultipart ? 'yes' : 'no'));
            error_log("Application data: " . json_encode($data));
            
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

            // Handle file uploads or set default values
            $profilePic = 'default_profile.jpg';
            $documentFile = 'default_document.pdf';

            if ($hasFiles) {
                // Process passport photo
                $picFile = $_FILES['passportPhoto'];
                $picExtension = pathinfo($picFile['name'], PATHINFO_EXTENSION);
                $profilePic = 'profile_' . time() . '_' . rand(1000, 9999) . '.' . $picExtension;
                move_uploaded_file($picFile['tmp_name'], $this->uploadDir['profile'] . $profilePic);
                
                // Process document
                $docFile = $_FILES['document'];
                $docExtension = pathinfo($docFile['name'], PATHINFO_EXTENSION);
                $documentFile = 'document_' . time() . '_' . rand(1000, 9999) . '.' . $docExtension;
                move_uploaded_file($docFile['tmp_name'], $this->uploadDir['document'] . $documentFile);
            }

            // Create application with both regular fields and file paths
            $sql = "INSERT INTO tblapply (UserID, SchemeId, ApplicationNumber, DateofBirth, 
                    Gender, Category, Major, Address, AshesiID, ProfilePic, DocReq, Status, ApplyDate) 
                    VALUES (:userId, :schemeId, :applicationNumber, :dateOfBirth, 
                    :gender, :category, :major, :address, :ashesiId, :profilePic, :docReq, '0', NOW())";
            
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
            $query->bindParam(':profilePic', $profilePic);
            $query->bindParam(':docReq', $documentFile);
            
            $query->execute();
            $applicationId = $this->db->lastInsertId();

            // Add documents to the documents table if we have actual files
            if ($hasFiles) {
                $this->addDocumentRecord($applicationId, $userId, 'passport_photo', $picFile['name'], $profilePic);
                $this->addDocumentRecord($applicationId, $userId, 'required_document', $docFile['name'], $documentFile);
            }
            
            echo json_encode([
                'message' => 'Application submitted successfully',
                'applicationId' => $applicationId,
                'applicationNumber' => $applicationNumber
            ]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to create application: ' . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to process application: ' . $e->getMessage()]);
        }
    }

    private function addDocumentRecord($applicationId, $userId, $documentType, $originalName, $storedFileName) {
        try {
            $basePath = ($documentType === 'passport_photo') ? $this->uploadDir['profile'] : $this->uploadDir['document'];
            $filePath = $storedFileName;
            
            $sql = "INSERT INTO tbldocuments (ApplicationID, UserID, DocumentType, DocumentName, FilePath) 
                    VALUES (:applicationId, :userId, :documentType, :documentName, :filePath)";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':applicationId', $applicationId);
            $query->bindParam(':userId', $userId);
            $query->bindParam(':documentType', $documentType);
            $query->bindParam(':documentName', $originalName);
            $query->bindParam(':filePath', $filePath);
            $query->execute();
            
            return true;
        } catch (PDOException $e) {
            error_log("Failed to add document record: " . $e->getMessage());
            return false;
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