<?php
require_once 'helpers/JWTHelper.php';
require_once 'helpers/ResponseHelper.php';

class NotificationController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        $id = $segments[1] ?? null;
        $userId = $_GET['userId'] ?? $id;

        
        switch($method) {
            case 'GET':
                $this->getNotifications($userId);
                break;
            case 'PUT':
                if ($id && isset($segments[2]) && $segments[2] === 'read') {
                    $this->markAsRead($id, $userId);
                } else {
                    ResponseHelper::error('Invalid action', 400);
                }
                break;
            default:
                ResponseHelper::error('Method not allowed', 405);
        }
    }

    private function getNotifications($userId) {
        try {
            $sql = "SELECT * FROM tblnotifications 
                    WHERE UserID = :userId 
                    ORDER BY CreatedAt DESC";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId);
            $query->execute();
            $notifications = $query->fetchAll(PDO::FETCH_ASSOC);
            
            ResponseHelper::success(['notifications' => $notifications]);
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Failed to fetch notifications', 500);
        }
    }

    private function markAsRead($id, $userId) {
        try {
            // Verify notification belongs to user
            $sql = "SELECT ID FROM tblnotifications 
                    WHERE ID = :id AND UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            
            if (!$query->fetch()) {
                ResponseHelper::error('Notification not found', 404);
                return;
            }

            // Mark as read
            $sql = "UPDATE tblnotifications 
                    SET IsRead = 1 
                    WHERE ID = :id AND UserID = :userId";
            
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $id);
            $query->bindParam(':userId', $userId);
            $query->execute();
            
            ResponseHelper::success(null, 'Notification marked as read');
        } catch (PDOException $e) {
            error_log("Database error: " . $e->getMessage());
            ResponseHelper::error('Failed to update notification', 500);
        }
    }
} 