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


    # Do not log attempts for common files
    #location ~ ^/(favicon.ico) {
    #    access_log off;
    #    log_not_found off;
    #}

    location @rewrite {
    # You have 2 options here
    # For D7 and above:
    # Clean URLs are handled in drupal_environment_initialize().
    rewrite ^ /index.php last;
    }

    # Do not log attempts for robots.txt
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Deny access to 'hidden' files and directories whose names
    # begin with a period.
    location ~ (^|/)\. {
        access_log off;
        log_not_found off;
        return 404;
    }

    # Deny obviously bad requests
    location ~ \.(jsp|cgi)$ {
        return 410;
    }

    # Deny access to files the public doesn't need
    location ~* ^.+(\.(txt|log|engine|inc|info|install|make|module|profile|test|po|sh|sql|theme|tpl(\.php)?|xtmpl))$ {
        internal;
    }

    # Deny access to other PHP files
    location ~ \..*/.*\.php {
        internal;
    }

    # Deny access to private and backups
    location ~* ^/sites/.*/(private|files/backup_migrate)/ {
        access_log off;
        return 404;
    }

    # Attempt to serve the request by trying direct file, directory, Drupal Controller
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        expires 1y;
    }

    # Check: http://wiki.nginx.org/Pitfalls
    location ~* ^/(install|update|apc|info)\.php {
        # do not cache dynamic content
        expires off;

        fastcgi_pass   unix:/var/run/php/php$5-fpm.sock;
        fastcgi_buffers 1024 4k;

        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    # Allow 'Well-Known URIs' as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Below locations are for image cache
    location ~* files/styles {
        access_log off;
        log_not_found off;
        expires 1y;
        try_files \$uri @image_rewrite;
    }

    location @image_rewrite {
        rewrite ^/(.*)$ /index.php?q=$1 last;
    }

    # Pass PHP scripts to PHP-FPM daemon
    # Check: http://wiki.nginx.org/Pitfalls
    location ~* \.php$ {
        # do not cache dynamic content
        expires off;

        # filter out problem conditions
        location ~ \..*/.*\.php$ { return 404; }

        fastcgi_pass   unix:/var/run/php/php$5-fpm.sock;
        fastcgi_buffers 1024 4k;

        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    # Directives to send expires headers and turn off 404 error logging for Static assets
    location ~* \.(?:css|js|jpe?g|gif|png|pdf|txt|woff2?)$ {
        access_log off;
        log_not_found off;
        expires 1y;
        add_header Cache-Control public;
    }

    # Shorter cache period to allow quicker client changes
    location ~* \.(?:ico)$ {
        access_log off;
        log_not_found off;
        expires 30d;
        add_header Cache-Control public;
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
