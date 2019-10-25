Step for run
* `Docker-compose up -d`
* Run `composer install` in container
* Extract file `1571850464_media_db_and_media.tgz`
  * Copy folder to folder `var` and `pub` to `application`
  * Create db name `test`
  * Import db from file `var/1571850464_db.sql`
 If already mysql or redis, can change config in `app/etc/env.php`
