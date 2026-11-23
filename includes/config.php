<?php
declare(strict_types=1);
return [
    'dsn' => 'mysql:host='.getenv('DB_HOST').';port='.(getenv('DB_PORT') ?: '3306').';dbname='.getenv('DB_NAME').';charset=utf8mb4',
    'user' => getenv('DB_USER'),
    'password' => getenv('DB_PASSWORD'),
];
