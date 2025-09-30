function takeoff
    set -l proxy_addr "http://127.0.0.1:7897"
    set -xg ALL_PROXY $proxy_addr
    set -xg HTTPS_PROXY $proxy_addr
    set -xg HTTP_PROXY $proxy_addr
end