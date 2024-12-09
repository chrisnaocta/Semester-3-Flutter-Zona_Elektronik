<?php
// Mengatur header agar dapat diakses oleh berbagai sumber (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json");

// Menghubungkan ke database
require "connect.php";

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $response = array(); // Inisialisasi array untuk respon
    $order_status = "Approved";

    // Mengambil data dari POST
    $idjual = $_POST['idjual'] ?? null;
    

    // Cek apakah field harga_produk dan id_produk terisi
    if (!empty($idjual)) {
        // Cek apakah pesanan ada di database
        $stmt1 = $connect->prepare("SELECT * FROM jual WHERE idjual = ?");
        $stmt1->bind_param("s", $idjual);
        $stmt1->execute();
        $result = $stmt1->get_result();     
        if ($row = $result->fetch_assoc()) {
            
        } else {
            $response['value'] = 0;
            $response['message'] = 'Pesanan tidak ditemukan.';
            echo json_encode($response);
            exit();
        }

        $stmt1 = $connect->prepare("UPDATE jual set order_status = ? WHERE idjual = ?");
        $stmt1->bind_param("ss", $order_status, $idjual);

        if ($stmt1->execute()) {
            $response['value'] = 1;
            $response['message'] = 'Pesanan berhasil diterima';
        } else {
            $response['value'] = 0;
            $response['message'] = 'Gagal saat menyimpan data: ' . $stmt->error;
        }
        $stmt1->close();
        
    } else {
        // Jika field harga_produk atau id_produk kosong
        $response['value'] = 0;
        $response['message'] = 'Field idjual tidak boleh kosong.';
    }

    // Mengembalikan respons dalam format JSON
    echo json_encode($response);
} else {
    // Jika request method bukan POST
    $response['value'] = 0;
    $response['message'] = 'Permintaan tidak valid.';
    echo json_encode($response);
}
?>