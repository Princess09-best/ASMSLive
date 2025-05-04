<?php
require_once('../includes/dbconnect.php');

try {
    // Create documents table
    $sql = "CREATE TABLE IF NOT EXISTS tbldocuments (
        ID int(11) NOT NULL AUTO_INCREMENT,
        ApplicationID int(11) NOT NULL,
        UserID int(11) NOT NULL,
        DocumentType varchar(100) NOT NULL,
        DocumentName varchar(255) NOT NULL,
        FilePath varchar(255) NOT NULL,
        UploadDate timestamp NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (ID),
        KEY idx_application_id (ApplicationID),
        KEY idx_user_id (UserID),
        CONSTRAINT fk_document_application FOREIGN KEY (ApplicationID) REFERENCES tblapply (ID) ON DELETE CASCADE,
        CONSTRAINT fk_document_user FOREIGN KEY (UserID) REFERENCES tbluser (ID) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    $db->exec($sql);
    
    echo "Documents table created successfully\n";
    
    // Create uploads directory if it doesn't exist
    $uploadDir = '../uploads/documents/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
        echo "Documents upload directory created successfully\n";
    }
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 