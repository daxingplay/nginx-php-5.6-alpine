FROM wodby/nginx-alpine
MAINTAINER Wodby <hello@wodby.com>

RUN echo 'http://alpine.gliderlabs.com/alpine/v3.4/main' > /etc/apk/repositories && \
    echo 'http://alpine.gliderlabs.com/alpine/v3.4/community' >> /etc/apk/repositories && \
    echo 'http://alpine.gliderlabs.com/alpine/edge/testing' >> /etc/apk/repositories && \
    echo 'http://alpine.gliderlabs.com/alpine/edge/community' >> /etc/apk/repositories && \

    # Install common packages
    apk add --update \
        openssh \
        git \
        nano \
        pcre \
        perl \
        patch \
        patchutils \
        diffutils

    # Add PHP actions
RUN cd /tmp && \
    git clone --depth=1 -b master https://GITHUB_ACCESS_TOKEN@github.com/Wodby/php-actions-alpine.git && \
    cd php-actions-alpine && \
    rsync -av rootfs/ /

    # Install specific packages
RUN apk add --update \
        mariadb-client \
        imap \
        redis \
        imagemagick \
        && \

    # Install PHP packages
    apk add --update \
        php5 \
        php5-common \
        php5-cli \
        php5-fpm \
        php5-opcache \
        php5-xml \
        php5-ctype \
        php5-ftp \
        php5-gd \
        php5-json \
        php5-posix \
        php5-curl \
        php5-dom \
        php5-pdo \
        php5-pdo_mysql \
        php5-sockets \
        php5-zlib \
        php5-mcrypt \
        php5-pcntl \
        php5-mysql \
        php5-mysqli \
        php5-sqlite3 \
        php5-bz2 \
        php5-pear \
        php5-exif \
        php5-phar \
        php5-openssl \
        php5-posix \
        php5-zip \
        php5-calendar \
        php5-iconv \
        php5-imap \
        php5-soap \
        php5-memcache \
        php5-redis \
        php5-xdebug \
        php5-xsl \
        php5-ldap \
        php5-bcmath

    # Configure php.ini
RUN sed -i \
        -e "s/^expose_php.*/expose_php = Off/" \
        -e "s/^;date.timezone.*/date.timezone = UTC/" \
        -e "s/^memory_limit.*/memory_limit = -1/" \
        -e "s/^max_execution_time.*/max_execution_time = 300/" \
        -e "s/^post_max_size.*/post_max_size = 512M/" \
        -e "s/^upload_max_filesize.*/upload_max_filesize = 512M/" \
        -e "s/^;always_populate_raw_post_data.*/always_populate_raw_post_data = -1/" \
        -e "s@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i -S opensmtpd:25@" \
        /etc/php5/php.ini && \

    echo "error_log = \"/var/log/php/error.log\"" | tee -a /etc/php5/php.ini && \

    # Configure php log dir
    mkdir -p /var/log/php && \
    touch /var/log/php/error.log && \
    touch /var/log/php/fpm-error.log && \
    touch /var/log/php/fpm-slow.log && \
    chown -R wodby:wodby /var/log/php && \

    # Install Twig template engine
    apk add --update \
        php5-dev \
        pcre-dev \
        build-base \
        autoconf \
        libtool

    # Install PHP extensions through Pecl
RUN sed -ie 's/-n//g' /usr/bin/pecl && \
    echo '\n' | pecl install uploadprogress && \
    apk --update add imagemagick-dev && \
    echo '\n' | pecl install imagick && \
    echo 'extension=imagick.so' > /etc/php5/conf.d/imagick.ini && \
    echo 'extension=uploadprogress.so' > /etc/php5/conf.d/uploadprogress.ini && \

    # Define Git global config
    git config --global user.name "Administrator" && \
    git config --global user.email "admin@wodby.com" && \
    git config --global push.default current && \

    # Disable Xdebug
    rm /etc/php5/conf.d/xdebug.ini && \

    # Install composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer config -g github-oauth.github.com GITHUB_ACCESS_TOKEN

    # Add composer parallel install plugin
RUN composer global require "hirak/prestissimo:^0.3"

    # Install drush
RUN php -r "readfile('https://s3.amazonaws.com/files.drush.org/drush.phar');" > /usr/local/bin/drush && \
    chmod +x /usr/local/bin/drush

    # Install Drupal Console
RUN curl https://drupalconsole.com/installer -o /usr/local/bin/drupal && \
    chmod +x /usr/local/bin/drupal

    # Install wp-cli
RUN composer create-project wp-cli/wp-cli /usr/local/src/wp-cli --no-dev && \
    ln -sf /usr/local/src/wp-cli/bin/wp /usr/bin/wp && \
    rm -rf /root/.composer/cache

    # Install Walter tool
RUN wget -qO- https://github.com/walter-cd/walter/releases/download/v1.3.0/walter_1.3.0_linux_amd64.tar.gz | tar xz -C /tmp/ && \
    mkdir /opt/wodby/bin && \
    cp /tmp/walter_linux_amd64/walter /opt/wodby/bin

    # Install Wellington tool
RUN wget -qO- https://s3.amazonaws.com/wodby-releases/wt/1.0.2/wt_v1.0.2_linux_amd64.tar.gz | tar xz -C /tmp/ && \
    cp /tmp/wt /opt/wodby/bin

    # Install go-aws-s3
RUN wget -qO- https://s3.amazonaws.com/wodby-releases/go-aws-s3/v1.0.0/go-aws-s3.tar.gz | tar xz -C /tmp/ && \
    cp /tmp/go-aws-s3 /opt/wodby/bin

    # Remove redis binaries and config
RUN ls /usr/bin/redis-* | grep -v redis-cli | xargs rm  && \
    rm -f /etc/redis.conf

    # Cleanup
RUN  apk del --purge \
        *-dev \
        build-base \
        autoconf \
        libtool

RUN rm -rf \
        /usr/include/php5 \
        /usr/lib/php5/build \
        /usr/lib/php5/modules/*.a \
        /var/cache/apk/* \
        /usr/share/man \
        /tmp/* \
        /root/.composer

COPY rootfs /
