#!/bin/bash

# Usage: ./http.sh <2|3> <url>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <2|3> <url>"
  exit 1
fi

version=$1
url=$2

if [[ "$version" != "2" && "$version" != "3" ]]; then
  echo "First argument must be either '2' for HTTP/2 or '3' for HTTP/3"
  exit 1
fi

check_http2() {
  response=$(curl -s -o /dev/null -w "%{http_version}" --http2 $url)
  if [[ "$response" == "2" || "$response" == "2.0" ]]; then
    echo -e "\e[32mHTTP/2 Supported\e[0m"
  else
    echo -e "\e[31mHTTP/2 Not Supported\e[0m"
  fi
  echo "Details:"
  curl -I --http2 $url
}

check_http3() {
  if ! command -v quick &> /dev/null; then
    echo -e "\e[31mError: 'quick' tool is not installed. Please install it to test HTTP/3.\e[0m"
    exit 1
  fi

  response=$(quick -s -o /dev/null -w "%H" $url 2>&1)
  # quick returns status and headers; checking for HTTP/3 presence in headers or response
  if echo "$response" | grep -q "^HTTP/3"; then
    echo -e "\e[32mHTTP/3 Supported\e[0m"
  else
    echo -e "\e[31mHTTP/3 Not Supported\e[0m"
  fi
  echo "Details:"
  quick -I $url
}

if [ "$version" == "2" ]; then
  check_http2
else
  check_http3
fi
