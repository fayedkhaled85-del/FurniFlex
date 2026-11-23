<?php
$path = rawurldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));
if ($path === '/' || $path === '/index.php') { require dirname(__DIR__).'/index.php'; return true; }
$root = realpath(dirname(__DIR__).'/assets');
$file = realpath(dirname(__DIR__).$path);
if ($file && str_starts_with($file, $root.DIRECTORY_SEPARATOR) && is_file($file)) return false;
http_response_code(404);
