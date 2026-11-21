<?php
$config = require '/var/www/html/FurniFlex/includes/config.php';
try {
    $db = new PDO($config['dsn'], $config['user'], $config['password']);
    if (!$db->query('SELECT product_id FROM products LIMIT 1')->fetchColumn()) exit(1);
    $page = file_get_contents('http://127.0.0.1/?page=shop');
    exit($page !== false && str_contains($page,'Arden Sofa') ? 0 : 1);
} catch (Throwable $error) { exit(1); }
