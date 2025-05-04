<?php
require_once 'helpers/JWTHelper.php';

class DocumentController {
    private $db;
    private $uploadDir = '../uploads/documents/';

    public function __construct($db) {
        $this->db = $db;
        // Create upload directory if it doesn't exist
        if (!file_exists($this->uploadDir)) {
            mkdir($this->uploadDir, 0777, true);
        }
    }

    public function handleRequest($method, $segments, $token) {
        // Verify token for all document endpoints
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            return;
        }

        $userData = JWTHelper::validateToken($token);
        if (!$userData) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid token']);
            return;
        }

        $id = $segments[1] ?? null;
        
        switch($method) {
            case 'GET':
                if ($id) {
                    $this->getDocument($id, $userData['userId']);
                } else {
                    $applicationId = $_GET['applicationId'] ?? null;
                    if ($applicationId) {
                        $this->listDocuments($applicationId, $userData['userId']);
                    } else {
                        http_response_code(400);
                        echo json_encode(['error' => 'Application ID required']);
                    }
                }
                break;
            case 'POST':
                $this->uploadDocument($userData['userId']);
                break;
            case 'DELETE':
                if ($id) {
                    $this->deleteDocument($id, $userData['userId']);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Document ID required']);
                }
                break;
            default:
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
        }
    }

    private function uploadDocument($userId) {
        try {
            if (!isset($_FILES['document'])) {
                http_response_code(400);
                echo json_encode(['error' => 'No file uploaded']);
                return;
            }

            if (!isset($_POST['applicationId']) || !isset($_POST['documentType'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Application ID and document type required']);
                return;
            }

            $applicationId = $_POST['applicationId'];
            $documentType = $_POST['documentType'];
            $file = $_FILES['document'];

            // Verify application belongs to user
            $sql = "SELECT ID FROM tblapply WHERE ID = :applicationId AND UserID = :userId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':applicationId', $applicationId);
            $query->bindParam(':userId', $userId);
            $query->execute();
            
            if (!$query->fetch()) {
                http_response_code(403);
                echo json_encode(['error' => 'Application not found or access denied']);
                return;
            }

            // Validate file type
            $allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
            if (!in_array($file['type'], $allowedTypes)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid file type. Only PDF, JPEG, and PNG allowed']);
                return;
            }

            // Generate unique filename
            $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
            $filename = uniqid() . '_' . time() . '.' . $extension;
            $filepath = $this->uploadDir . $filename;

            // Move uploaded file
            if (move_uploaded_file($file['tmp_name'], $filepath)) {
                // Save document info to database
                $sql = "INSERT INTO tbldocuments (ApplicationID, UserID, DocumentType, DocumentName, FilePath) 
                        VALUES (:applicationId, :userId, :documentType, :documentName, :filePath)";
                
                $query = $this->db->prepare($sql);
                $query->bindParam(':applicationId', $applicationId);
                $query->bindParam(':userId', $userId);
                $query->bindParam(':documentType', $documentType);
                $query->bindParam(':documentName', $file['name']);
                $query->bindParam(':filePath', $filename);
                $query->execute();

                echo json_encode([
                    'message' => 'Document uploaded successfully',
                    'documentId' => $this->db->lastInsertId()
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to upload file']);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save document information']);
        }
    }

    private function listDocuments($applicationId, $userId) {
        try {
            $sql = "SELECT d.*, a.ApplicationNumber 
                    FROM tbldocuments d 
                    JOIN tblapply a ON d.ApplicationID = a.ID 
                    WHERE d.ApplicationID = :applicationId AND d.UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':applicationId', $applicationId);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $documents = $query->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['documents' => $documents]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch documents']);
        }
    }

    private function getDocument($id, $userId) {
        try {
            $sql = "SELECT d.*, a.ApplicationNumber 
                    FROM tbldocuments d 
                    JOIN tblapply a ON d.ApplicationID = a.ID 
                    WHERE d.ID = :id AND d.UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $document = $query->fetch(PDO::FETCH_ASSOC);
            
            if ($document) {
                echo json_encode(['document' => $document]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Document not found']);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch document']);
        }
    }

    private function deleteDocument($id, $userId) {
        try {
            // First get the document to check ownership and get filename
            $sql = "SELECT FilePath FROM tbldocuments WHERE ID = :id AND UserID = :userId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $document = $query->fetch(PDO::FETCH_ASSOC);

            if (!$document) {
                http_response_code(404);
                echo json_encode(['error' => 'Document not found or access denied']);
                return;
            }

            // Delete file
            $filepath = $this->uploadDir . $document['FilePath'];
            if (file_exists($filepath)) {
                unlink($filepath);
            }

            // Delete database record
            $sql = "DELETE FROM tbldocuments WHERE ID = :id AND UserID = :userId";
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();

            echo json_encode(['message' => 'Document deleted successfully']);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to delete document']);
        }
    }
} 