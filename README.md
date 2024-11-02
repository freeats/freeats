# Toughbyte FreeATS

## Getting started

### Docker

1. Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
   and make sure the Docker server is running by using the command

   ```shell
   docker info
   ```

2. Download the repository, you can do this via git or by downloading the zip file.

3. Navigate to the project directory and build the Docker services:

   ```shell
   docker compose build
   docker compose run --rm web bundle exec rake db:create db:migrate
   ```

4. To start the server, run the following command:

   ```shell
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
   docker rmi ats-web
   docker rmi postgres:15
   ```

### Troubleshooting

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
