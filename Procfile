web: bin/rails server -p $PORT -e $RAILS_ENV
worker: BACKGROUND_JOB=1 WEB_CONCURRENCY=0 bundle exec rake solid_queue:start
release: bin/rake db:migrate
