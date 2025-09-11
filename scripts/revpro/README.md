# CMNDS Reverse Proxy Manager (revpro)
- works with `docker-compose.yml` here, but you need to specify the volume mounts manually, if you use different /revpro folder...


# HTTP/3

It isn't complicated to setup, but here are few things you must do:

- use `template/http3.conf` in /revpro/misc folder
- generate quic_host.key: `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /revpro/quic/quic_host.key -out /revpro/quic/quic_host.crt` (change path)
- bind quic_host.key to the container:
   ```
  # QUIC
  - /revpro/quic/quic_host.key:/etc/nginx/ssl/quic_host.key
  ```
- Allow **UDP** === ESSENTIAL ===; foe. in docker compose ports:
  ```
  - "80:80/tcp"
  - "80:80/udp"
  - "443:443/tcp"
  - "443:443/udp"
  ```

- nginx.conf add to http:
  ```
  # Global HTTP/3  
  http3_stream_buffer_size 1m;
  quic_retry on;
  ssl_early_data on;
  quic_gso on;
  quic_host_key /etc/nginx/ssl/quic_host.key;
  ...
  ...
  ...
  server {
        listen 443 quic reuseport;
        http2 on;
        http3 on;
        http3_hq on;
        quic_retry on;

        server_name _;
        location / {
           add_header Alt-Svc 'h3=":$server_port"; ma=86400';
           add_header x-quic 'h3';
           add_header Alt-Svc 'h3-29=":$server_port"';
        }
    }
  ```

Test on https://http3check.net/
