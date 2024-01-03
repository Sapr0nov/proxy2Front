<?php
require_once($_SERVER['HOME'] . '/html/api/v1/ProxyClass.php');

$url = 'https://al-a.ru/' . $_SERVER['REQUEST_URI'];
$method = $_SERVER['REQUEST_METHOD'];

$opts = file_get_contents("php://input");
$result = Proxy::sendRequest($url, $opts);


$obj = json_decode($result, true);
$body = json_decode($obj['body'], true);

# Здесь меняем нужные параметры
if (isset($body['data'])) {
    $body['data']['time'] = '12/23/32';
}

# //Здесь меняем нужные параметры

print_r(json_encode($body));
?>
