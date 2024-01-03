<?php
Class Proxy {
    static function sendRequest($url, $options ='') :string
    {
        $http_headers_orig = getallheaders();
        if (!$http_headers_orig) {
            $http_headers = array(
                'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2',
                'Accept: */*',
                'Connection: keep-alive',
            );
        }else{
            $http_headers_orig['Host'] = 'al-a.ru';
            $http_headers_orig['Origin'] = 'al-a.ru';
            $http_headers_orig['Referer'] = 'al-a.ru/';
            $http_headers = Proxy::convHeaders($http_headers_orig);
        }
                
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_HEADER, TRUE);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $http_headers);

        if (strlen($options) > 1) {
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $options);
        }

        $response = curl_exec($ch);
        $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        $headers = substr($response, 0, $header_size);
        $body = substr($response, $header_size);
        curl_close($ch);
        if (strlen($headers) > 0) {
            $heads = (explode("\r\n",$headers));
            foreach ($heads as $key => $value) {
                if (strlen($key) > 0 ) {
                    header($key. ':'.$value);
                }
            }
        }
        return json_encode(array('body' => $body));
    }

    static private function convHeaders($headers):array {
        $result = array();
        foreach ($headers as $name => $value) {
            // устанавливаем тип ответа
            if (stripos($name,"Content-type") !== false) {
                header(trim($name.": ".$value));
            }
            $result[] = $name . ': ' . $value;
        }
        
        return $result;
    }

    static private function convCookies($cookies):array {
        $result = array();
        foreach ($cookies as $name => $value) {
            $result[] = 'Cookie: ' . $name . '=' . $value;
        }
        return $result;
    }

}

?>