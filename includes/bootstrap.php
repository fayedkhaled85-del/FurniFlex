<?php
declare(strict_types=1);
ini_set('session.use_strict_mode','1');
session_set_cookie_params(['lifetime'=>0,'path'=>'/','secure'=>!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off','httponly'=>true,'samesite'=>'Lax']);
session_start();
require __DIR__.'/functions.php';
function db(): PDO { static $pdo=null; if($pdo) return $pdo; $cfg=require __DIR__.'/config.php'; $pdo=new PDO($cfg['dsn'],$cfg['user'],$cfg['password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);return $pdo; }
