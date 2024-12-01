<?php

$connect = new
mysqli("localhost", "root", "", "db_zonaelektronik");
if($connect){
    }else{
        echo "Koneksi gagal";
        exit();
    }

?>