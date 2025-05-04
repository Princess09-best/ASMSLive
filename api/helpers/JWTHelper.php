<?php
require_once __DIR__ . '/../../vendor/autoload.php';
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;

class JWTHelper {
    private static $key = '4sh3s1_Sch0l4rsh1p_S3cr3t_2024'; // Secure key for JWT
    private static $algorithm = 'HS256';

    public static function generateToken($userId, $email) {
        $issuedAt = time();
        $expirationTime = $issuedAt + (60 * 60 * 24); // Token valid for 24 hours
        
        $payload = array(
            'iat' => $issuedAt,
            'exp' => $expirationTime,
            'userId' => $userId,
            'email' => $email
        );
        
        return JWT::encode($payload, self::$key, self::$algorithm);
    }

    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(self::$key, self::$algorithm));
            return (array) $decoded;
        } catch (Exception $e) {
            error_log("JWT Error: " . $e->getMessage());
            return false;
        }
    }
} 