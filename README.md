# Toughbyte FreeATS

## Getting started

### Docker

1. Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
   and make sure the Docker server is running by using the command

   ```shell
   docker info
   ```

2. Download the repository, you can do this via git or by downloading the zip file.

3. Decide what database (containerized or external) you will use.\
   This app currently supports only PostgreSQL.\
   Use docker-compose file `app_with_containerized_db.yml` if you want to use a containerized database.\
   Use docker-compose file `app_with_external_db.yml` if you want to use own database.

4. Navigate to the project directory and build the Docker services:

   ```shell
   docker compose -f <docker_compose_file> build
   docker compose -f <docker_compose_file> run --rm web bundle exec rake db:create db:migrate
   ```

5. To start the server, run the following command:

   ```shell
   docker compose -f <docker_compose_file> up -d
   ```

6. Open `http://<your_server_ip>:3000/register` and create an account.

7. To stop the running containers, use the following command:

   ```shell
   docker compose -f <docker_compose_file> stop
   ```

8. To remove the created images, containers and volumes, use the following commands:

   ```shell
   docker compose -f <docker_compose_file> down --volumes
   docker rmi freeats-web
   docker rmi postgres:15 # if you use containerized database.
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
