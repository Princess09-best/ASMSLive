<?php
require_once('../includes/dbconnect.php');

try {
    // Create notifications table
    $sql = "CREATE TABLE IF NOT EXISTS tblnotifications (
        ID int(11) NOT NULL AUTO_INCREMENT,
        UserID int(11) NOT NULL,
        Message text NOT NULL,
        Type varchar(50) NOT NULL, 
        IsRead tinyint(1) NOT NULL DEFAULT 0,
        RelatedID int(11) DEFAULT NULL,
        RelatedType varchar(50) DEFAULT NULL,
        CreatedAt timestamp NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (ID),
        KEY idx_user_id (UserID),
        KEY idx_is_read (IsRead),
        CONSTRAINT fk_notification_user FOREIGN KEY (UserID) REFERENCES tbluser (ID) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    $db->exec($sql);
    
    echo "Notification table created successfully\n";
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 