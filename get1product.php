<?php
session_start();
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json");

require "connect.php"; // Pastikan file ini mengatur koneksi ke database

// Tangani preflight request untuk CORS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Pastikan hanya menerima metode POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode([
        'status' => 'error', 
        'message' => 'Metode tidak diizinkan'
    ]);
    exit();
}

// Baca raw input dari body request
$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);

// Periksa apakah idproduct ada di input
if (!isset($input['idproduct'])) {
    http_response_code(400); // Bad Request
    echo json_encode([
        'status' => 'error', 
        'message' => 'ID product tidak diberikan'
    ]);
    exit();
}

// Ambil dan sanitasi idproduct
$idproduct = mysqli_real_escape_string($connect, $input['idproduct']);

// Log untuk debugging
error_log('idproduct yang diterima: ' . $idproduct);

// Query untuk mengambil data pengguna berdasarkan idproduct
$query = "SELECT * FROM namaproduct WHERE idproduct = '$idproduct'";
$result = mysqli_query($connect, $query);

if ($result) {
    if (mysqli_num_rows($result) > 0) {
        // Pengguna ditemukan
        $product = mysqli_fetch_assoc($result);
        $response = [
            'status' => 'success', 
            'data' => $product
        ];
        http_response_code(200);
    } else {
        // Pengguna tidak ditemukan
        $response = [
            'status' => 'error', 
            'message' => 'Pengguna tidak ditemukan'
        ];
        http_response_code(404);
    }
} else {
    // Kesalahan query
    $response = [
        'status' => 'error', 
        'message' => 'Kesalahan query database: ' . mysqli_error($connect)
    ];
    http_response_code(500);
}

// Tutup koneksi database
mysqli_close($connect);

// Kirim respons JSON
echo json_encode($response);
?>