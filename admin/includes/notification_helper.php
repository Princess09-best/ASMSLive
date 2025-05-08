<?php
class NotificationHelper {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function createApplicationStatusNotification($userId, $applicationId, $status, $schemeName) {
        $title = "Application Status Update";
        $message = "Your application for $schemeName has been $status";
        $type = $status === "Approved" ? "success" : "warning";
        
        $sql = "INSERT INTO tblnotifications (UserID, Title, Message, Type, ActionType, ActionId, IsRead) 
                VALUES (:userId, :title, :message, :type, 'view-application', :actionId, 0)";
        
        try {
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId, PDO::PARAM_INT);
            $query->bindParam(':title', $title, PDO::PARAM_STR);
            $query->bindParam(':message', $message, PDO::PARAM_STR);
            $query->bindParam(':type', $type, PDO::PARAM_STR);
            $query->bindParam(':actionId', $applicationId, PDO::PARAM_INT);
            return $query->execute();
        } catch (PDOException $e) {
            error_log("Error creating notification: " . $e->getMessage());
            return false;
        }
    }

    public function createScholarshipNotification($userId, $scholarshipId, $scholarshipName, $type = 'info') {
        $title = "New Scholarship Available";
        $message = "A new scholarship '$scholarshipName' is now available for application";
        
        $sql = "INSERT INTO tblnotifications (UserID, Title, Message, Type, ActionType, ActionId, IsRead) 
                VALUES (:userId, :title, :message, :type, 'view-scholarship', :actionId, 0)";
        
        try {
            $query = $this->db->prepare($sql);
            $query->bindParam(':userId', $userId, PDO::PARAM_INT);
            $query->bindParam(':title', $title, PDO::PARAM_STR);
            $query->bindParam(':message', $message, PDO::PARAM_STR);
            $query->bindParam(':type', $type, PDO::PARAM_STR);
            $query->bindParam(':actionId', $scholarshipId, PDO::PARAM_INT);
            return $query->execute();
        } catch (PDOException $e) {
            error_log("Error creating notification: " . $e->getMessage());
            return false;
        }
    }

    public function markNotificationAsRead($notificationId) {
        $sql = "UPDATE tblnotifications SET IsRead = 1 WHERE ID = :id";
        try {
            $query = $this->db->prepare($sql);
            $query->bindParam(':id', $notificationId, PDO::PARAM_INT);
            return $query->execute();
        } catch (PDOException $e) {
            error_log("Error marking notification as read: " . $e->getMessage());
            return false;
        }
    }
}
?> 