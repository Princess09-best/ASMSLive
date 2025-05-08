<?php
require_once __DIR__ . '/../helpers/JWTHelper.php';

class BankDetailsController {
    private $db;
    public function __construct($db) {
        $this->db = $db;
    }

    public function handleRequest($method, $segments, $token) {
        if ($method === 'POST') {
            $this->submitBankDetails($token);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
    }

    private function submitBankDetails($token) {
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            $userId = $data['userId'];

            // Validate required fields
            $required = ['applicationId', 'accountHolderName', 'bankName', 'branchName', 'swiftCode', 'accountNumber'];
            foreach ($required as $field) {
                if (empty($data[$field])) {
                    http_response_code(400);
                    echo json_encode(['error' => "Missing field: $field"]);
                    return;
                }
            }

            // Check if already submitted for this application
            $sql = "SELECT ID FROM tblbankdetails WHERE UserID = :uid AND ApplicationNumber = :appnumber";
            $query = $this->db->prepare($sql);
            $query->bindParam(':uid', $userId);
            $query->bindParam(':appnumber', $data['applicationId']);
            $query->execute();
            if ($query->fetch()) {
                http_response_code(400);
                echo json_encode(['error' => 'Bank details already submitted for this application']);
                return;
            }

            // Insert bank details
            $sql = "INSERT INTO tblbankdetails (ApplicationNumber, UserID, AccountHoldername, BankName, BranchName, IFSCCode, AccountNumber)
                    VALUES (:appnumber, :uid, :accholdername, :bankname, :branchname, :ifsc, :accountnumber)";
            $query = $this->db->prepare($sql);
            $query->bindParam(':uid', $userId);
            $query->bindParam(':appnumber', $data['applicationId']);
            $query->bindParam(':accholdername', $data['accountHolderName']);
            $query->bindParam(':bankname', $data['bankName']);
            $query->bindParam(':branchname', $data['branchName']);
            $query->bindParam(':ifsc', $data['swiftCode']);
            $query->bindParam(':accountnumber', $data['accountNumber']);
            $query->execute();

            echo json_encode(['message' => 'Bank details submitted successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
        }
    }
}