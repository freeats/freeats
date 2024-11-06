# Toughbyte FreeATS

## Quick start

1. Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
   and make sure the Docker server is running by using the command

   ```shell
   docker info
   ```

2. Download the repository, you can do this via git or by downloading the zip file.

3. Prepare values for sensitive variables:

   `SECRET_KEY_BASE` - a secret key for the application, example: "462d54c7b15dcc1924e797d0b28e6d"\
   `POSTGRES_USER` - a username for the PostgreSQL database, example: "postgres"\
   `POSTGRES_PASSWORD` - a password for the PostgreSQL database, example: "password"

4. Navigate to the project directory and start the application:

   ```shell
   SECRET_KEY_BASE=<value> \
   POSTGRES_USER=<value> \
   POSTGRES_PASSWORD=<value> \
   docker compose up -d
   ```

5. Open `http://<your_server_ip>:3000/register` and create an account.

6. To stop the running containers, use the following command:

   ```shell
   docker compose stop
   ```

7. To remove the created images, containers and volumes, use the following commands:

   ```shell
   docker compose down --volumes
   docker rmi freeats-web
   docker rmi postgres:15
   ```

## Run the application with your own database

This app currently supports only PostgreSQL.

1. Prepare values for sensitive variables:

   `SECRET_KEY_BASE` - a secret key for the application, example: "462d54c7b15dcc1924e797d0b28e6d"\
   `DATABASE_URL` - a URL to the PostgreSQL database, example: "postgres://postgres:password@localhost:5432/freeats"

2. Navigate to the project directory and start the application:

   ```shell
   DATABASE_URL=<database_url> \
   SECRET_KEY_BASE=<value> \
   docker compose -f app_with_external_db.yml up -d
   ```

3. To stop the running containers, use the following command:

   ```shell
   docker compose -f app_with_external_db.yml stop
   ```

4. To remove the created images, containers and volumes, use the following commands:

   ```shell
   docker compose -f app_with_external_db.yml down --volumes
   docker rmi freeats-web
   ```

## Troubleshooting

- If you have an unstable internet connection, there may be errors.
  If this happens, restart the command that failed.

- If you get the error `address already in use`, it is most likely
  because port 5432 is being used by local PostgreSQL service.
  It can be checked using command:

  ```shell
  sudo lsof -i :5432
  ```

  Local PostgreSQL service then can be stopped:

  ```shell
  sudo systemctl stop postgresql
  ```

  More details on [stackoverflow](https://stackoverflow.com/questions/38249434/docker-postgres-failed-to-bind-tcp-0-0-0-05432-address-already-in-use).

- If files with root permissions were created during the process,
  you can change them using the command

  ```shell
  chmod -R 777 <file or directory name>
  ```
