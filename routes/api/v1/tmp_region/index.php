<?php
require_once($_SERVER["HOME"] . '/html/api/v1/ProxyClass.php');

$url = "https://al-a.ru/" . $_SERVER['REQUEST_URI'];
$method = $_SERVER['REQUEST_METHOD'];

$opts = file_get_contents("php://input");
$result = Proxy::sendRequest($url, $opts);

$obj = json_decode($result, true);

if (isset($obj["body"])) {
    $body = json_decode($obj["body"], true);
}else{
    return false;
}

# Здесь меняем нужные параметры
if (isset($body['data']) && isset($body['data']['name'])) {
    $body['data']['name'] = "МОЯ " . $body['data']['name'];
    $body['data']['new_filed'] = "Новое поле";
}
# //Здесь меняем нужные параметры

print_r(json_encode($body));

?>
