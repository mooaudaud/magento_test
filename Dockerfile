FROM ubuntu:16.04
MAINTAINER Phachara Srisura "phachara@shopstack.asia"

# SERVICE: Supervisord
RUN apt-get update && apt-get install -y locales postfix mailutils telnet supervisor cron vim curl && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/log/supervisor
COPY ./etc/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Add user
RUN groupadd -r -g 539 magento \
&& useradd -m -r -u 539 magento -g 539 -c "magento role account"

##Mkdir
RUN mkdir /application && chown -R magento.magento /application
ADD ./application /application
RUN chown -R magento.magento /application

###UTF-8
#RUN apt-get update && apt-get -y install locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#cron mangeto
ADD ./etc/cron/magento /etc/cron.d/magento
RUN chmod 0644 /etc/cron.d/magento
RUN crontab /etc/cron.d/magento
RUN touch /var/log/cron.log
#CMD cron && tail -f /var/log/cron.log



# SERVICE: Nginx
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        nginx \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mv /etc/nginx/sites-available/default /etc/nginx/conf.d/default.conf \
    && rm -rf /etc/nginx/sites-available /etc/nginx/sites-enable

COPY ./etc/nginx/nginx.conf /etc/nginx/
COPY ./etc/nginx/default.conf /etc/nginx/conf.d/

# SERVICE: PHP-FPM
RUN apt-get update && \
    apt-get install -y software-properties-common python-software-properties && \
    add-apt-repository -y -u ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y imagemagick graphicsmagick && \
    apt-get install -y php-redis libapache2-mod-php7.0 php7.0-bcmath php7.0-fpm php7.0-bz2 php7.0-cli php7.0-common php7.0-curl php7.0-dba php7.0-gd php7.0-gmp php7.0-imap php7.0-intl php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-odbc php7.0-pgsql php7.0-recode php7.0-snmp php7.0-soap php7.0-sqlite php7.0-tidy php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip && \
    apt-get install -y php-gnupg php-imagick php-mongodb php-streams php-fxsl

RUN mkdir -p /var/log/php/ /run/php

## PHP Configuration

COPY ./etc/php/php.ini ./etc/php/php-fpm.conf /etc/php/7.0/fpm/
COPY ./etc/php/www.conf /etc/php/7.0/fpm/pool.d/


### SSH
#RUN apt-get update && apt-get install -y openssh-server curl
#RUN mkdir /var/run/sshd
#RUN echo 'root:aye123!!!' | chpasswd
#RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

### SSH login fix. Otherwise user is kicked off after login
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

#ENV NOTVISIBLE "in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile

# Install git
RUN apt-get update \
&& apt-get -y install git \
&& apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

#Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN su magento -c "composer"

#ADD Key CE
ADD ./etc/key/.composer/auth.json /home/magento/.composer/
RUN chown -R magento.magento /home/magento/

# Common
EXPOSE 80 443 22 25

VOLUME ["/var/log"]

CMD ["/usr/bin/supervisord"]

