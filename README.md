# Toughbyte FreeATS

## Quick start

1. Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
   and make sure the Docker server is running by using the command

   ```shell
   docker info
   ```

2. Download the repository, you can do this via git or by downloading the zip file.

3. Navigate to the project directory and start the application:

   ```shell
   docker compose up -d
   ```

4. Open `http://<your_server_ip>:3000/register` and create an account.

5. To stop the running containers, use the following command:

   ```shell
   docker compose stop
   ```

6. To remove the created images, containers and volumes, use the following commands:

   ```shell
   docker compose down --volumes
   docker rmi freeats-web
   docker rmi postgres:15
   ```

## Run the application with your own database

This app currently supports only PostgreSQL. You must provide the database URL.

1. Navigate to the project directory and start the application:

   ```shell
   DATABASE_URL=<database_url> docker compose -f app_with_external_db.yml up -d
   ```

2. To stop the running containers, use the following command:

   ```shell
   docker compose -f app_with_external_db.yml stop
   ```

3. To remove the created images, containers and volumes, use the following commands:

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
