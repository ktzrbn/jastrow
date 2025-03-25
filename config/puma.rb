workers 2
threads 1, 4
bind "unix:///var/www/jastrow/tmp/puma.sock"
environment "production"
pidfile "/var/www/jastrow/tmp/puma.pid"
stdout_redirect "/var/www/jastrow/log/puma.log", "/var/www/jastrow/log/puma_err.log", true
