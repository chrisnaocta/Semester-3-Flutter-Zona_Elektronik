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

// Periksa apakah email ada di input
if (!isset($input['email'])) {
    http_response_code(400); // Bad Request
    echo json_encode([
        'status' => 'error', 
        'message' => 'Email tidak diberikan'
    ]);
    exit();
}

// Ambil dan sanitasi email
$email = mysqli_real_escape_string($connect, $input['email']);

// Log untuk debugging
error_log('Email yang diterima: ' . $email);

// Query untuk mengambil data pengguna berdasarkan email
$query = "SELECT id_user FROM users WHERE email = '$email'";
$result = mysqli_query($connect, $query);

if ($result) {
    if (mysqli_num_rows($result) > 0) {
        // Pengguna ditemukan
        $user = mysqli_fetch_assoc($result);

        $id_user = $user['id_user'];

        // Query untuk mengambil data pesanan pengguna
        $query = "SELECT j.idjual, j.tgljual, j.bukti_trf, j.idproduct, j.price, j.quantity, j.id_pembeli, j.email, j.nama, j.alamat, j.telepon, j.order_status, p.product 
        FROM jual j INNER JOIN namaproduct p ON j.idproduct = p.idproduct WHERE (id_pembeli = '$id_user' AND order_status = 'Waiting')";
        $result = mysqli_query($connect, $query);

        $pesanan = array();

        while ($row = mysqli_fetch_assoc($result)){
            $pesanan[] = $row;
        }

        $response = [
            'status' => 'success', 
            'data' => $pesanan,
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