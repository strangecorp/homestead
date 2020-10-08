block="server {
    listen ${3:-80};
    listen ${4:-443} ssl http2;
    server_name .$1;

    ## Access and error logs
    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    ## Filesystem root of the site and index.
    root $2;

    index index.php;

    ## Body size
    #client_max_body_size 5M;
    connection_pool_size 200m;
    large_client_header_buffers 4 200m;
    client_max_body_size 200m;
    keepalive_timeout 10m;

    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    ## FastCGI params
    fastcgi_send_timeout 60s;
    fastcgi_read_timeout 60s;
    fastcgi_connect_timeout 60s;

    fastcgi_buffer_size 128k;
    fastcgi_buffers 4 256k;
    fastcgi_busy_buffers_size 256k;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)$ {
        allow 192.168.0.0/16;
        deny all;
    }

    location ~ \..*/.*\.php$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Allow \"Well-Known URIs\" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to \"hidden\" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        # try_files \$uri @rewrite; # For Drupal <= 6
        try_files \$uri /index.php?\$query_string; # For Drupal >= 7
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.php?q=\$1;
    }

    # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php$ {
        deny all;
        return 404;
    }

    # In Drupal 8, we must also match new paths where the '.php' appears in
    # the middle, such as update.php/selection. The rule we use is strict,
    # and only allows this pattern with the update.php front controller.
    # This allows legacy path aliases in the form of
    # blog/index.php/legacy-path to continue to route to Drupal nodes. If
    # you do not have any paths like that, then you might prefer to use a
    # laxer rule, such as:
    #   location ~ \.php(/|$) {
    # The laxer rule will continue to work if Drupal uses this new URL
    # pattern with front controllers other than update.php in a future
    # release.
    location ~ '\.php$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
        # Security note: If you're running a version of PHP older than the
        # latest 5.3, you should have \"cgi.fix_pathinfo = 0;\" in php.ini.
        # See http://serverfault.com/q/627903/94922 for details.
        include fastcgi_params;
        # Block httpoxy attacks. See https://httpoxy.org/.
        fastcgi_param HTTP_PROXY \"\";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param QUERY_STRING \$query_string;
        fastcgi_intercept_errors on;
        # PHP socket location.
        fastcgi_pass   unix:/var/run/php/php$5-fpm.sock;
        fastcgi_buffers 1024 4k;
    }

    # Fighting with Styles? This little gem is amazing.
    # location ~ ^/sites/.*/files/imagecache/ { # For Drupal <= 6
    location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
        try_files \$uri @rewrite;
    }

    # Handle private files through Drupal. Private file's path can come
    # with a language prefix.
    location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
        try_files \$uri /index.php?\$query_string;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }

    # Nginx gzip_static does not add Vary header for fonts.
    location ~* \.(?:eot|ttf|svg)$ {
        access_log off;
        log_not_found off;
        expires 1y;
        add_header Cache-Control public;
        add_header Vary Accept-Encoding;
    }

    gzip on;
    gzip_disable \"msie6\";

    gzip_comp_level 6;
    gzip_min_length 1100;
    gzip_buffers 16 8k;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/js
        text/xml
        text/javascript
        application/javascript
        application/x-javascript
        application/json
        application/xml
        application/xml+rss
        image/svg+xml;
    gzip_vary on;

    ssl_certificate     /etc/nginx/ssl/$1.crt;
    ssl_certificate_key /etc/nginx/ssl/$1.key;
}"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
