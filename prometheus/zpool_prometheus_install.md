# Installing zpool_prometheus

Deb pkgs:

- `zpool_prometheus` (depends on zfs, which should be already installed in our case)
- `python3` (already installed)
- `uwsgi`
- `uwsgi-plugin-python3`
- `nginx`

Conf files:

- `zpool_prometheus_nginx.conf` -> `/etc/nginx/sites-available` and linked to sites-enabled
- `zpool_prometheus.service` -> `/etc/systems/system/zpool_prometheus.service`
- `zpool_prometheus_wsgi.ini` -> `/opt/serve_zpool_prometheus`
- `zpool_prometheus_wsgi.py` -> `/opt/serve_zpool_prometheus`
- `serve_zpool_prometheus.py` -> `/opt/serve_zpool_prometheus`

The prometheus.service file references the `/opt/serve_zpool_prometheus` location. Change is that is not the install target.

The `zpool_prometheus_nginx.conf` and `zpool_prometheus_wsgi.ini` files reference the socket location below.

Shell commands:

`mkdir /var/run/zpool_prometheus`
`chown www-data.www-data /var/run/zpool_prometheus`

How it works:

nginx listens on port 5001 and upstreams http requests to the socket
uwsgi listens on the socket and runs python+flask+serve_zpool_prometheus.py
server_zpool_prometheus.py runs the zpool_prometheus command
