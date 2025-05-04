<?php
require_once(__DIR__ . '/../includes/dbconnect.php');

try {
    $stmt = $db->query('SHOW TABLES');
    echo "Tables in the database:\n";
    echo "----------------------\n";
    
    while($row = $stmt->fetch(PDO::FETCH_NUM)) {
        echo "- " . $row[0] . "\n";
    }
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 