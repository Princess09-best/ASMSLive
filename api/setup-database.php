<?php
// Database configuration
$host = 'localhost';
$user = 'root';
$pass = '';
$dbname = 'webtech_fall2024_princess_balogun';

try {
    // Create connection without database
    $pdo = new PDO("mysql:host=$host", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Create database if it doesn't exist
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `$dbname`");
    echo "Database created or already exists successfully\n";
    
    // Select the database
    $pdo->exec("USE `$dbname`");
    
    // Create users table
    $pdo->exec("CREATE TABLE IF NOT EXISTS `tbluser` (
        `ID` int(11) NOT NULL AUTO_INCREMENT,
        `FullName` varchar(120) DEFAULT NULL,
        `Email` varchar(120) DEFAULT NULL,
        `MobileNumber` varchar(11) DEFAULT NULL,
        `Password` varchar(255) DEFAULT NULL,
        `RegDate` timestamp NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1");
    echo "Users table created successfully\n";
    
    // Create schemes table
    $pdo->exec("CREATE TABLE IF NOT EXISTS `tblscheme` (
        `ID` int(11) NOT NULL AUTO_INCREMENT,
        `SchemeName` varchar(120) DEFAULT NULL,
        `SchemeType` varchar(120) DEFAULT NULL,
        `Description` mediumtext DEFAULT NULL,
        `Eligibility` varchar(120) DEFAULT NULL,
        `LastDate` date DEFAULT NULL,
        `PublishedDate` timestamp NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1");
    echo "Schemes table created successfully\n";
    
    // Create applications table
    $pdo->exec("CREATE TABLE IF NOT EXISTS `tblapply` (
        `ID` int(11) NOT NULL AUTO_INCREMENT,
        `UserID` int(11) DEFAULT NULL,
        `SchemeId` int(11) DEFAULT NULL,
        `ApplicationNumber` varchar(120) DEFAULT NULL,
        `DateofBirth` date DEFAULT NULL,
        `Gender` varchar(50) DEFAULT NULL,
        `Category` varchar(120) DEFAULT NULL,
        `Major` varchar(120) DEFAULT NULL,
        `Address` mediumtext DEFAULT NULL,
        `AshesiID` varchar(120) DEFAULT NULL,
        `Status` varchar(120) DEFAULT '0',
        `ApplyDate` timestamp NULL DEFAULT current_timestamp(),
        `Remark` varchar(120) DEFAULT NULL,
        `UpdationDate` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
        PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1");
    echo "Applications table created successfully\n";
    
    // Create documents table
    $pdo->exec("CREATE TABLE IF NOT EXISTS `tbldocuments` (
        `ID` int(11) NOT NULL AUTO_INCREMENT,
        `ApplicationID` int(11) NOT NULL,
        `UserID` int(11) NOT NULL,
        `DocumentType` varchar(50) NOT NULL,
        `DocumentName` varchar(255) NOT NULL,
        `FilePath` varchar(255) NOT NULL,
        `UploadDate` timestamp NULL DEFAULT current_timestamp(),
        `Status` enum('pending','approved','rejected') DEFAULT 'pending',
        PRIMARY KEY (`ID`),
        KEY `ApplicationID` (`ApplicationID`),
        KEY `UserID` (`UserID`),
        CONSTRAINT `tbldocuments_ibfk_1` FOREIGN KEY (`ApplicationID`) REFERENCES `tblapply` (`ID`) ON DELETE CASCADE,
        CONSTRAINT `tbldocuments_ibfk_2` FOREIGN KEY (`UserID`) REFERENCES `tbluser` (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    echo "Documents table created successfully\n";
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 