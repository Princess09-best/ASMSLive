<?php
require_once 'helpers/JWTHelper.php';

class ScholarshipController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        // Validate token for protected routes
        if ($method !== 'GET') {
            $userData = JWTHelper::validateToken($token);
            if (!$userData) {
                http_response_code(401);
                echo json_encode(['error' => 'Unauthorized']);
                return;
            }
        }

        $id = $segments[1] ?? null;

        switch($method) {
            case 'GET':
                if ($id) {
                    $this->getScholarship($id);
                } else {
                    $this->listScholarships();
                }
                break;
            default:
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
        }
    }

    private function listScholarships() {
        try {
            $sql = "SELECT * FROM tblscheme WHERE LastDate >= CURDATE() ORDER BY PublishedDate DESC";
            $query = $this->db->prepare($sql);
            $query->execute();
            $scholarships = $query->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['scholarships' => $scholarships]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch scholarships']);
        }
    }

    private function getScholarship($id) {
        try {
            $sql = "SELECT * FROM tblscheme WHERE ID = :id";
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->execute();
            $scholarship = $query->fetch(PDO::FETCH_ASSOC);
            
            if ($scholarship) {
                echo json_encode(['scholarship' => $scholarship]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Scholarship not found']);
            }
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch scholarship']);
        }
    }
} 