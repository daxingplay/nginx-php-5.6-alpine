FROM wodby/php-actions-alpine:v1.0.14
MAINTAINER Wodby <hello@wodby.com>

RUN export NGX_VER="1.9.3" && \
    export NGX_UP_VER="0.9.0" && \
    export NGX_LUA_VER="0.9.16" && \
    export NGX_NDK_VER="0.2.19" && \
    export NGX_NXS_VER="0.54rc3" && \
    export LUAJIT_LIB="/usr/lib/" && \
    export LUAJIT_INC="/usr/include/luajit-2.0/" && \
    export PHP_VER="5.6.12" && \
    export TWIG_VER="1.21.1" && \
    export WCLI_VER="0.1" && \
    export WALTER_VER="1.3.0" && \
    export GO_AWS_S3_VER="v1.0.0" && \

    echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \

    # Quick fix.
    apk add --update \
        nmap-ncat \
        busybox-suid \
        pwgen \
        && \

    apk add --update git sed nmap pwgen openssh rsync msmtp patch patchutils inotify-tools mariadb-client wget grep \
    redis nano bash diffutils imagemagick php-cli php-fpm php-opcache php-xml php-ctype php-ftp php-gd php-json \
    php-posix php-curl php-dom php-pdo php-pdo_mysql php-sockets php-zlib php-mcrypt php-mysqli php-bz2 php-pear \
    php-phar php-openssl php-posix phpredis@testing php-zip php-calendar php-iconv php-imap tar gzip pcre perl curl nmap-ncat && \
    wget -qO- https://github.com/walter-cd/walter/releases/download/v${WALTER_VER}/walter_${WALTER_VER}_linux_amd64.tar.gz | tar xz -C /tmp/ && \
    mkdir /opt/wodby/bin && \
    cp /tmp/walter_linux_amd64/walter /opt/wodby/bin && \
    apk add --update build-base php-dev php-pear autoconf imagemagick-dev libtool pcre-dev && \
    sed -ie 's/-n//g' `which pecl` && \
    pecl install xdebug && pecl install uploadprogress && printf '\n' | pecl install imagick && \
    curl -L http://php.net/get/php-${PHP_VER}.tar.gz/from/this/mirror | tar xz -C /tmp && \
    cd /tmp/php-${PHP_VER}/ext/pcntl && \
    phpize && ./configure && make && make install && \
    wget -qO- https://github.com/twigphp/Twig/archive/v${TWIG_VER}.tar.gz | tar xz -C /tmp/ && \
    cd /tmp/Twig-${TWIG_VER}/ext/twig && \
    phpize && ./configure && make && make install && \
    cd / && rm -rf /tmp/* && \
    ln -sf /usr/bin/msmtp /usr/sbin/sendmail && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && \
    cd /usr/local/src/drush && \
    ln -sf /usr/local/src/drush/drush /usr/bin/drush && \
    composer install && rm -rf ./.git && \
    composer create-project wp-cli/wp-cli /usr/local/src/wp-cli --no-dev && \
    ln -sf /usr/local/src/wp-cli/bin/wp /usr/bin/wp && \
    git config --global user.name "Administrator" && git config --global user.email "admin@wodby.com" && git config --global push.default current && \
    chmod 755 /root && \

    # Install go-aws-s3
    wget -qO- https://s3.amazonaws.com/wodby-releases/go-aws-s3/${GO_AWS_S3_VER}/go-aws-s3.tar.gz | tar xz -C /tmp/ && \
    cp /tmp/go-aws-s3 /opt/wodby/bin && \

    # Configure php.ini
    sed -i "s/^expose_php.*/expose_php = Off/" /etc/php/php.ini && \
    sed -i "s/^;date.timezone.*/date.timezone = UTC/" /etc/php/php.ini && \
    sed -i "s/^memory_limit.*/memory_limit = -1/" /etc/php/php.ini && \
    sed -i "s/^max_execution_time.*/max_execution_time = 300/" /etc/php/php.ini && \
    sed -i "s/^post_max_size.*/post_max_size = 512M/" /etc/php/php.ini && \
    sed -i "s/^upload_max_filesize.*/upload_max_filesize = 512M/" /etc/php/php.ini && \
    echo "extension_dir = \"/usr/lib/php/modules\"" | tee -a /etc/php/php.ini && \
    echo "error_log = \"/var/log/php/error.log\"" | tee -a /etc/php/php.ini && \

    # Configure php log dir
    mkdir /var/log/php && \
    touch /var/log/php/error.log && \
    touch /var/log/php/fpm-error.log && \
    touch /var/log/php/fpm-slow.log && \
    chown -R wodby:wodby /var/log/php && \

    # Clear apk cache
    rm -rf /var/cache/apk/* /tmp/* /usr/bin/su

COPY rootfs /
