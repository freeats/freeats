# Toughbyte FreeATS

## Getting started

### How to run locally in developer mode

#### Docker

1. Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
   and make sure the Docker server is running by using the command

   ```shell
     docker info
   ```

2. Set up the development environment:

   ```shell
      docker compose build
      docker compose run --rm web bundle exec rake db:create db:migrate db:fixtures:load
   ```

3. To start the Rails server, run `docker compose up`
4. Open <http://localhost:3000> and login with `admin@mail.com:password`.
5. If the Rails server is up, tests can be run using:
   ```shell
      docker compose exec web rails test
   ```
   If the Rails server is down, you can use:
   ```shell
      docker compose run web rails test
   ```
6. Similarly, use these commands to run a bash console, depending on the state of the Rails server:
   ```shell
      docker compose exec web bash   # If the server is up
      docker compose run web bash    # If the server is down
   ```
7. To stop the running containers, use the following command:

   ```shell
      docker compose stop
   ```

#### Troubleshooting

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
