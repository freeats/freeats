web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bin/bundle exec rake solid_queue:start
release: bin/rake db:migrate
