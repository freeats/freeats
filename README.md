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

3. Ask for two private keys from other developers and place them in the following directories:

   - `master.key` - `config`
   - `test.key` - `config/credentials`

4. Install the right Ruby version:

   ```shell
   $ grep "ruby \"" Gemfile
   $ rvm install <version>
   $ rvm --default use <version>
   ```

5. Install PostgreSQL using [this instruction](https://wiki.archlinux.org/index.php/PostgreSQL).
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

6. Create a user and databases:

   ```shell
   $ sudo -u postgres psql < db/postgres/init.sql
   ```

7. Install [NodeJS](https://nodejs.org/en/download/package-manager) and
   [yarn](https://yarnpkg.com/en/docs/install).

8. Install JavaScript and Ruby dependencies:

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

9. Prepare the database:

   ```shell
   $ bin/rails db:migrate         # Update the DB and the schema
   ```

10. Prepare image-related library, we used it for ActiveStorage image processing:

    ```shell
    $ sudo apt install libvips
    ```

11. Run tests to make sure everything is configured correctly:

    ```shell
    $ bin/spring rails test
    ```

12. Run Rails:

    ```shell
    $ bin/dev
    ```

13. Open <http://localhost:3000>.

## Staging environment

How to run it locally:

1. Set environment variables in `.env.staging`:

   ```
   HOST_URL=http://localhost:3000
   DATABASE_URL=ats_staging
   ```

2. Precompile assets with `rails assets:precompile`.
3. Setup the database with `RAILS_ENV=staging rails db:setup db:fixtures:load`.
4. Run the server with `RAILS_ENV=staging rails server`.

After finishing work, run `rails assets:clobber` to remove precompiled assets.

## Credentials management

We use builtin Rails feature for credentials management. First, make sure that
you have an `EDITOR` environment variable set up, for example, for VSCode it
could be `EDITOR="code --wait"`. Next make sure that you have the necessary
key to decipher credentials: the main key is located at `config/master.key`,
it is responsible for the "default" key. Environment-specific keys are located
at `config/credentials/`, they override any default values in the master
credentials.

You can edit credentials:

```shell
# Edit master credentials
$ rails credentials:edit

# Edit production credentials (same applies for development, test and staging)
$ rails credentials:edit -e production
```

You can use credentials in code where each YAML key corresponds to a method or
a hash key:

```ruby
# For credentials:
# amazon:
#   access_key_id: "access_key"
#   secret_access_key: "secret_key"
#   bucket: bucket-name

# When we don't know if `amazon` key is present at all.
Rails.application.credentials.dig(:amazon, :access_key_id)

# When we are fine if `access_key_id` is not present.
Rails.application.credentials.amazon.access_key_id

# If we insist that `access_key_id` must be present.
Rails.application.credentials.amazon.access_key_id!
```

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

### Staging environment

For demonstration purposes we have a working deployed project with staging
environment at <https://ats.toughbyte.com>.
There we can bypass Google OAuth authentication and use these
endpoints to authenticate as different roles:

- Admin -- <https://ats.toughbyte.com/staging-environment-only/please-login?email=admin%40mail.com>
- Employee -- <https://ats.toughbyte.com/staging-environment-only/please-login?email=employee%40mail.com>
- Hiring manager -- <https://ats.toughbyte.com/staging-environment-only/please-login?email=hiring_manager%40mail.com>
- Interviewer -- <https://ats.toughbyte.com/staging-environment-only/please-login?email=interviewer%40mail.com>
- Inactive -- <https://ats.toughbyte.com/staging-environment-only/please-login?email=inactive%40mail.com>

## Deployment

### Dokku

Install Dokku by running the following command on the server:

```shell
wget -N https://dokku.com/install/v0.33.6/bootstrap.sh && \
    sudo DOKKU_TAG=v0.33.6 bash bootstrap.sh
```

Create new app.

```shell
dokku apps:create ats
```

Setup Postgres database.

```shell
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git && \
    sudo dokku postgres:create ats_database && \
    dokku postgres:link ats_database ats
```

Install Herokuish Buildpacks.

```shell
dokku buildpacks:add ats https://github.com/heroku/heroku-buildpack-ruby.git && \
    dokku config:set ats BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-ruby.git
```

Setup environments.
First, a master key should be generated on the local machine.

```shell
git clone https://github.com/toughbyte/ats && \
    cd ats && \
    rm config/credentials.yml.enc && \
    EDITOR="cat" rails credentials:edit && \
    cat config/master.key
```

Copy the master key from the console output and use it on the
server to set `RAILS_MASTER_KEY` using the following command:

```shell
dokku config:set ats RAILS_MASTER_KEY=<paste_master_key_here>
```

Also the new encrypted credentials config should be committed to Git repository.
To do this, run the following command on the local machine.

```shell
git add config/credentials.yml.enc && \
    git commit -m "new credentials.yml.enc" && \
    git push
```

Set the allowed file size that could be uploaded.
Dokku uses Nginx and can reject post requests with big file sizes.
In this case, we have to set the `client_max_body_size` value
and set `NGINX_FILE_SIZE_LIMIT_IN_MEGA_BYTES` to display a warning in the interface.

```shell
dokku config:set ats NGINX_FILE_SIZE_LIMIT_IN_MEGA_BYTES=<value_in_megabytes>
value=$(dokku config:get ats NGINX_FILE_SIZE_LIMIT_IN_MEGA_BYTES)
dokku nginx:set ats client-max-body-size "$value"m && dokku proxy:build-config ats
```

Setup certificate for domain.
Let's assume that your primary email address for deployment is
`admin@toughbyte.com` and the domain is `ats.toughbyte.com`.
Then use this email and domain directly in the commands:

```shell
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git && \
    dokku letsencrypt:set --global email admin@toughbyte.com && \
    dokku domains:clear ats && \
    dokku domains:add ats ats.toughbyte.com && \
    dokku letsencrypt:enable ats && \
    dokku letsencrypt:cron-job --add ats && \
    dokku letsencrypt:set ats graceperiod 2592000
```

Set `HOST_URL` environment variable as your domain name, it's necessary to generate links:

```shell
dokku config:set ats HOST_URL=<your_domain>
```

If the docker cache takes up a lot of space, it can be cleared it with the following command:

```shell
sudo docker system prune
```

### Github actions

Configure GitHub deploy: add `DOKKU_SSH_PRIVATE_KEY` to [github secrets].
To get the private rsa key, execute the following command on the server:

```shell
cat ~/.ssh/id_rsa
```

If the server doesn't have the rsa key, it can be generated by the command:

```shell
ssh-keygen -t rsa
```

[github secrets]: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-an-environment

### Fill in default data

First we need to mount the directory into the ats docker container.
This can be done using the following command:

```shell
mkdir ~/shared_dir && \
    dokku storage:mount ats ~/shared_dir:/app/tmp/shared_dir
```

Next `csv` files should be uploaded to mounted directory (`~/shared_dir`).
Run the following command to import all default values of tables:

```shell
dokku run ats bin/rails runner scripts/import_from_csv/import_from_csv.rb tmp/shared_dir/locations.csv Location && \
    dokku run ats bin/rails runner scripts/import_from_csv/import_from_csv.rb tmp/shared_dir/location_hierarchies.csv LocationHierarchy && \
    dokku run ats bin/rails runner scripts/import_from_csv/import_from_csv.rb tmp/shared_dir/location_aliases.csv LocationAlias && \
    dokku run ats bin/rails runner scripts/import_from_csv/import_from_csv.rb tmp/shared_dir/candidate_sources.csv CandidateSource
```

### AWS S3

TODO

### Google OAuth

Application uses Google OAuth 2.0 system for authentication requiring only
access to email and not keeping any tokens for offline actions. In order
to set up this system, the following actions should be performed:

1. Go to <https://console.developers.google.com/>.
1. Select your project (or create it) in the upper left corner.
1. Go to "OAuth consent screen" tab.
1. Assuming you own a Gmail domain for you company, choose "internal" type.
   This will avoid any reviews from Google and you won't need to write
   documents on data policy and privacy.
1. Record your Gmail domain there, links to documents can be any links to
   the deployed instance, no one checks them.
1. Save and next.
1. In "Scopes" choose "Add or remove scopes" and choose only email scope
   `.../auth/userinfo.email`.
1. Finish setting the consent screen.
1. Go to "Credentials" tab.
1. Click "Create credentials" -> "OAuth client ID".
1. In "Application type" choose "Web application".
1. Under "Authorized redirect URIs" add a new item and, if your website is
   deployed at `example.com`, the URI should be
   `https://example.com/auth/google_oauth2/callback`.
1. Fill all necessary fields and save it.
1. Save "Client ID" and "Client secret" for further use.
1. Open a terminal and go to the project root, e.g. `cd projects/ats`.
1. Open production credentials with `rails credentials:edit -e production`.
1. Fill in the keys `client_id` and `client_secret` in `google_oauth`.
1. Close and save it.

Now you should be able to log in into the application.

### Gmail integration

Application uses Gmail integration for synchronizing email messages.
The user can choose which emails he/she wants to synchronize. For this to
work we need to set up a Google OAuth integration (similar to authentication).
In order to set up this system, the following actions should be performed:

1. Go to <https://console.developers.google.com/>.
1. Create new project in the upper left corner. If you have a project set up
   for authentication, this will require another project. Separate projects will
   be used for authentication and email synchronization because they require
   different permissions.
1. Go to "Enabled APIs & services", click "Enable APIs and services".
1. In the search bar find "Gmail".
1. Click "Enable".
1. Go to "OAuth consent screen" tab.
1. Assuming you own a Gmail domain for you company, choose "internal" type.
   This will avoid any reviews from Google and you won't need to write
   documents on data policy and privacy.
1. Record your Gmail domain there, links to documents can be any links to
   the deployed instance, no one checks them.
1. Save and next.
1. In "Scopes" choose "Add or remove scopes" and choose full email access
   `https://mail.google.com/`.
1. Finish setting the consent screen.
1. Go to "Credentials" tab.
1. Click "Create credentials" -> "OAuth client ID".
1. In "Application type" choose "Web application".
1. Under "Authorized redirect URIs" add a new item and, if your website is
   deployed at `example.com`, the URI should be
   `https://example.com/ats/profile/link-email`.
1. Fill all necessary fields and save it.
1. Save "Client ID" and "Client secret" for further use.
1. Open a terminal and go to the project root, e.g. `cd projects/ats`.
1. Open production credentials with `rails credentials:edit -e production`.
1. Fill in the keys `client_id` and `client_secret` in `gmail_linking`.
1. Close and save it.

Now you should be able to link emails.

## Administration

### Accounts

Accounts are implemented via two separate tables: `accounts` and `members`.
`accounts` table works solely with authentication logic, it only contains
the bare minimum information to authenticate a user and some common things
for representation like name and avatar. Next `members` table
is actually responsible for authorization with its `access_level` and it
has a one-to-one relation with `accounts`.

How to add a new account:

1. Go to admin panel at `/admin`.
2. Choose "Accounts" table on the left.
3. Click on "Add new" tab.
4. Fill in name and email. Make sure to enter the email from your owned
   Gmail domain, otherwise the authentication via Google OAuth will not work.
5. Save the record. It will appear at the very top of the list without any
   members assigned to it.
6. Go to "Members" table on the left.
7. Click on "Add new" tab.
8. Choose the newly created account and choose the appropriate access level.
   All other fields are optional.
9. Save the record.

Now you have successfully created a new account. This person can now log in
using Google OAuth with the email above.

How to deactivate an account:

1. Go to admin panel at `/admin`.
2. Choose "Members" table on the left.
3. Search the member by their email address.
4. On the right side of the table there're several actions available. To the
   **FAR** right there's a circled cross icon, when hovered over with mouse it shows
   "Deactivate" text. **Do not confuse it** with the the "Delete" operation
   which is a bare cross icon.
5. Click on "Deactivate" icon.

Now the member is considered deactivated and they will lose any access to
their account but their information will be still available in the system.

How to reactivate an account:

1. Go to admin panel at `/admin`.
2. Choose "Members" table on the left.
3. Search the member by their email address.
4. Click on the pencil icon, it has an "Edit" text when hovered with mouse.
5. Choose the appropriate access level.
6. Save the record.

Now the member will be considered active again and will be able to log into
the system.
