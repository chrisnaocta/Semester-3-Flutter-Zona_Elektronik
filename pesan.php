<?php
// Mengatur header agar dapat diakses oleh berbagai sumber (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json");

// Menghubungkan ke database
require "connect.php";

function generateCustomId($connect) {
    // Dapatkan tanggal hari ini
    $tanggal = date('Ymd');
    
    // Prefix ID
    $prefix = 'JP-' . $tanggal;
    
    // Cari nomor urut terakhir hari ini
    $stmt = $connect->prepare("SELECT MAX(SUBSTRING(idjual, -4)) as max_urut 
                                FROM jual 
                                WHERE idjual LIKE ?");
    $like_pattern = $prefix . '%';
    $stmt->bind_param("s", $like_pattern);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    
    // Tentukan nomor urut
    $urut = $row['max_urut'] ? intval($row['max_urut']) + 1 : 1;
    
    // Format nomor urut dengan padding
    $nomor_urut = sprintf("%04d", $urut);
    
    // Gabungkan menjadi ID lengkap
    return $prefix . $nomor_urut;
}

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $response = array(); // Inisialisasi array untuk respon

    // Mengambil data dari POST
    $id_produk = $_POST['id_produk'] ?? null;
    $quantity = $_POST['quantity'] ?? 1;
    $email = $_POST['email'] ?? null;
    $tanggal = date('Y-m-d');
    error_log('email pembeli:' . $email);
    

    // Cek apakah field harga_produk dan id_produk terisi
    if (!empty($quantity) && !empty($id_produk)) {
        // Generate custom ID
        $custom_id = generateCustomId($connect);

        // Cek + ambil data produk
        $stmt1 = $connect->prepare("SELECT price FROM namaproduct WHERE idproduct = ?");
        $stmt1->bind_param("s", $id_produk);
        $stmt1->execute();
        $result = $stmt1->get_result();     
        if ($row = $result->fetch_assoc()) {
            $price = $row['price']; 
        } else {
            $response['value'] = 0;
            $response['message'] = 'Barang tidak ditemukan.';
            echo json_encode($response);
            exit();
        }

        // Mengambil data user berdasarkan email dari tabel users. data user pada saat memesan 
        // dimasukan ke data pemesanan karena data user seperti alamat bisa saja berubah di masa depan
        $stmt1 = $connect->prepare("SELECT id_user, nama, alamat, telepon FROM users WHERE email = ?");
        $stmt1->bind_param("s", $email);
        $stmt1->execute();
        $result = $stmt1->get_result();
        
        // Cek apabila user ada
        if ($row = $result->fetch_assoc()) {
            $id_pembeli = $row['id_user'];
            $nama = $row['nama'];
            $alamat = $row['alamat'];
            $telepon = $row['telepon'];

            // Handle bukti transfer terlebih dahulu
            $uploadDir = 'bukti_trf/';
            $allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];

            // Mengamankan nama file
            $fotoFileName = null;
            if (isset($_FILES['bukti_trf'])) {
                $profileFoto = $_FILES['bukti_trf'];
                $fileName = $profileFoto['name'];
                $fileTmp = $profileFoto['tmp_name'];
                $fileSize = $profileFoto['size'];
                $fileType = mime_content_type($fileTmp);

                // Check if the file is an image and within size limits (2MB in this example)
                if (in_array($fileType, $allowedTypes) && $fileSize <= 2 * 1024 * 1024) {
                    // Create the destination path for the file (save with userId as the filename)
                    $fileExtension = pathinfo($fileName, PATHINFO_EXTENSION); // Get the file extension (jpg, png, jpeg)
                    $fotoFileName = $custom_id . '.' . $fileExtension; // Format nama file <id_user>.<ext>
                    $uploadPath = $uploadDir . $fotoFileName;

                    // Pindahkan file ke folder uploads
                    if (move_uploaded_file($fileTmp, $uploadPath)) {
                        $bukti_trf = $fotoFileName; // Untuk dimasukan ke database
                    } else {
                        $response['value'] = 0;
                        $response['message'] = 'Gagal mengunggah file foto';
                        echo json_encode($response);
                        exit(); // Hentikan eksekusi jika gagal upload
                    }
                } else {
                    $response['value'] = 0;
                    $response['message'] = 'File yang diupload harus berupa gambar JPG/PNG/JPEG dan maksimal 2MB.';
                    echo json_encode($response);
                    exit();
                }
            } else {
                $response['value'] = 0;
                $response['message'] = 'File tidak ditemukan.';
                echo json_encode($response);
                exit();
            }

            // Menggunakan prepared statement 
            $order_status = 'Waiting';
            $stmt = $connect->prepare("INSERT INTO jual (idjual, tgljual, bukti_trf, idproduct, price, quantity, id_pembeli, email, nama, alamat, telepon, order_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->bind_param("ssssdissssss", $custom_id, $tanggal, $bukti_trf, $id_produk, $price, $quantity, $id_pembeli, $email, $nama, $alamat, $telepon, $order_status);
            // 's' = string, 'd' = double, 'i' = integer

            // Menjalankan query
            if ($stmt->execute()) {
                // Jika penyimpanan berhasil
                $response['value'] = 1;
                $response['message'] = 'Pembelian berhasil diproses';
                $response['idjual'] = $custom_id; // Tambahkan ID yang baru dibuat
            } else {
                // Jika terjadi kesalahan saat menyimpan
                $response['value'] = 0;
                $response['message'] = 'Gagal saat menyimpan data: ' . $stmt->error;
            }

            // Tutup statement
            $stmt->close();
        } else {
            $response['value'] = 0;
            $response['message'] = 'User tidak ditemukan';
        }

        // Tutup statement pencarian user
        $stmt1->close();
    } else {
        // Jika field harga_produk atau id_produk kosong
        $response['value'] = 0;
        $response['message'] = 'Field quantity dan id_produk tidak boleh kosong.';
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