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

## Authentication

For authentication we use the [rodauth] gem together with [rodauth-rails] and
[rodauth-model] gems for easier integration with Rails. We use OAuth
authentication via Google and we use gems [omniauth], [omniauth-google-oauth2]
and [rodauth-omniauth] to integrate it.

[rodauth]: https://github.com/jeremyevans/rodauth
[rodauth-rails]: https://github.com/janko/rodauth-rails
[rodauth-model]: https://github.com/janko/rodauth-model
[omniauth-google-oauth2]: https://github.com/zquestz/omniauth-google-oauth2
[omniauth]: https://github.com/omniauth/omniauth
[rodauth-omniauth]: https://github.com/janko/rodauth-omniauth

### Working in development

In production the only way to authenticate is through Google OAuth.
In development we need an alternative way of doing authentication to not
depend on internet connection and Google services. Currently we have this
setup that is tuned for usage with fixtures in app/misc/rodauth_app.rb:

- By default you are logged in with an `admin@mail.com` email. Logging in
  attempt happens with every request so you can't log out in this mode.

- If you would like to log in as another user, provide their email in the
  `AUTH_EMAIL` environment variable:

  ```sh
  AUTH_EMAIL=employee@mail.com rails s
  ```

- If you would like to avoid getting automatically logged in,
  set the `AUTH_NOLOGIN` environment variable. In this mode you can manually
  log out if you want to.

  ```sh
  AUTH_NOLOGIN=1 rails s
  ```

### Tests

We have a special route set up that is active only in testing in
app/misc/rodauth_app.rb: `/test-environment-only/please-login`. It accepts
an `email` query parameter with which to log in. For ease of use we have
helpers in test/test_helper.rb so testing is easier:

```rb
# Supply the account to log in
sign_in accounts(:employee_account)

# Loggin out works as in production without any magic
sign_out
```

### Testing OmniAuth

We have a test Google OAuth instance set up that works both in development
and production. Credentials are recorded in config/credentials.yml.enc.
In order to test it, you will need to do two things:

```shell
# Create an account with your email
rake 'auth:setup_account[dmitry.matveyev@toughbyte.com]'

# Start the server without automatic login
AUTH_NOLOGIN=1 rails s
```
