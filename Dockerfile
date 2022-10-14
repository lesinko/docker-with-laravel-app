
FROM tangramor/nginx-php8-fpm

# copy source code
COPY . /var/www/html

# If there is a conf folder under /var/www/html, the start.sh will
COPY ./nginx.conf /etc/nginx/default.conf

# Set environment files
ENV COMPOSERMIRROR=""
ENV NPMMIRROR=""
ENV WEBROOT /var/www/html/public
ENV PHP_REDIS_SESSION_HOST redis
ENV CREATE_LARAVEL_STORAGE "1"
ENV TZ Africa/Nairobi

# download required node/php packages,
# some node modules need gcc/g++ to build
RUN if [[ "$APKMIRROR" != "" ]]; then sed -i "s/dl-cdn.alpinelinux.org/${APKMIRROR}/g" /etc/apk/repositories ; fi\
    && apk add --no-cache --virtual .build-deps gcc g++ libc-dev make \
    # set preferred npm mirror
    && cd /usr/local \
    && if [[ "$NPMMIRROR" != "" ]]; then npm config set registry ${NPMMIRROR}; fi \
    && npm config set registry $NPMMIRROR \
    && cd /var/www/html \
    # install node modules
    && npm install \
    # install php composer packages
    && if [[ "$COMPOSERMIRROR" != "" ]]; then composer config -g repos.packagist composer ${COMPOSERMIRROR}; fi \
    && composer install \
    # clean
    && apk del .build-deps \
    # Set permissions for public folder
    && chmod -R 777 /var/www/html/public \
    # build js/css
    && npm run production

# set .env, check if .env exists if not try to copy env.test if that fails copy .env.example
RUN  printf "\
if [ ! -e .env ]; then \n \
    if [ -e .env.test ]; then \n \
        cp .env.test .env \n \
    else \n \
        if [ -e .env.example ]; then \n \
            cp .env.example .env \n\
        fi \n \
    fi \n \
    # Generate key \n \
    php artisan key:generate \n \
fi" > temp.sh \
    && chmod +x temp.sh \
    && ./temp.sh \
    && rm temp.sh

# change /var/www/html user/group
RUN chown -Rf nginx:nginx /var/www/html

# Set directory permissions
RUN chmod -R 777 /var/www/html/storage

# Delete the nginx.conf file in the container
RUN rm -rf /var/www/html/nginx.conf
