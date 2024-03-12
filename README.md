# Toughbyte ATS

## Getting started

### Linux

1. It's recommended to install [RVM](https://rvm.io/rvm/install). If you use rbenv, please
   uninstall it and remove `~/.rbenv` to avoid dependencies conflicts.

2. Clone the repo and `cd` to the directory:

   ```shell
   $ git clone git@github.com:toughbyte/ats.git
   $ cd ats
   ```

3. Install the right Ruby version:

   ```shell
   $ grep "ruby \"" Gemfile
   $ rvm install <version>
   $ rvm --default use <version>
   ```

4. Install PostgreSQL using [this instruction](https://wiki.archlinux.org/index.php/PostgreSQL).
   The process is similar for most of Linux distributions.
   On Ubuntu, PostgreSQL can be installed by entering these commands:

   ```shell
   $ sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
   $ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
   $ sudo apt-get update
   $ sudo apt-get -y install postgresql
   ```

   On Ubuntu, additional steps might be required:

   - Open `/etc/postgresql/<version_number>/main/pg_hba.conf` and change `md5` to `trust` in the
     last column for the following lines:

     ```
     host    all             all             127.0.0.1/32            trust
     host    all             all             ::1/128                 trust
     ```

   - Restart the PostgreSQL service.

5. Create a user and databases:

   ```shell
   $ sudo -u postgres psql < db/postgres/init.sql
   ```

6. Install [NodeJS](https://nodejs.org/en/download/package-manager) and
   [yarn](https://yarnpkg.com/en/docs/install).

7. Install JavaScript and Ruby dependencies:

   ```shell
   $ bin/yarn
   $ bin/yarn build
   $ bin/yarn build:css
   $ bin/bundle install
   ```

   On Ubuntu, 'bundle install' may result in an error stating a problem with pg gem.
   To fix this issue enter the following command:

   ```shell
   $ sudo apt-get install libpq-dev
   ```

   After that, retry the bundle install again:

   ```shell
   $ bin/bundle install
   ```

8. Prepare the database:

   ```shell
   $ bin/rails db:migrate         # Update the DB and the schema
   ```

9. Prepare image-related library, we used it for ActiveStorage image processing:

     ```shell
     $ sudo apt install libvips
     ```

10. Run tests to make sure everything is configured correctly:

    ```shell
    $ bin/spring rails test
    ```

11. Run Rails:

    ```shell
    $ bin/dev
    ```

12. Open <http://localhost:3000>.
