#!/bin/sh -eux
# Install Ruby, Git, Node, Postgres, and Redis

# Use UTF-8 for everything
sudo locale-gen en_US.UTF-8

echo "LANG=en_US.UTF-8
LANGUAGE=
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8" | sudo tee /etc/default/locale

# Download no additional languages
sudo touch /etc/apt/apt.conf.d/00aptitude
echo 'Acquire::Languages "none";' | sudo cat /etc/apt/apt.conf.d/00aptitude

# skip this, but if using behind a firewall you'll want these
# echo 'Acquire::http::Proxy "http://proxy";
# Acquire::https::Proxy "http://proxy";' | sudo cat /etc/apt/apt.conf
# 
# sudo rm -rf /etc/wgetrc
# echo "http_proxy = http://proxy
# https_proxy = http://proxy" | sudo tee /etc/wgetrc
# sudo chmod 755 /etc/wgetrc
# 
# sudo rm -rf /etc/curlrc
# echo 'user-agent="foo;"
# proxy=http://proxy' | sudo tee /etc/curlrc
# sudo chmod 755 /etc/curlrc

sudo apt-get -y install \
  linux-headers-$(uname -r) \
  asciidoc \
  automake \
  build-essential \
  curl \
  docbook2x \
  dkms \
  firefox \
  fontconfig \
  g++ \
  gcc \
  gettext \
  git-core \
  graphviz \
  gstreamer1.0-plugins-base \
  gstreamer1.0-tools \
  gstreamer1.0-x \
  libssl-dev \
  libcurl4-openssl-dev \
  libevent-dev \
  libexpat1-dev \
  libffi-dev \
  libgdbm-dev \
  libgdbm3 \
  libqt5webkit5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libxml2-dev \
  libxslt1-dev \
  libxslt-dev \
  libsqlite3-dev \
  libssl-dev \
  libyaml-dev \
  make \
  ncurses-dev \
  python-software-properties \
  qt5-default \
  redis-server \
  software-properties-common \
  sqlite3 \
  tcl \
  unzip \
  vim \
  wget \
  x11-xkb-utils \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  xfonts-cyrillic \
  xmlto \
  xvfb \
  zlib1g-dev \
  zsh

# install newer version of git
cd ~
wget --quiet https://github.com/git/git/archive/v2.9.0.zip
unzip -q v2.9.0.zip
cd git-*
make prefix=/usr/local all
sudo make prefix=/usr/local install
cd ~
sudo rm -rf ~/git-2.9.0
sudo rm -rf ~/v2.9.0.zip

# install ruby
cd ~
wget --quiet https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz
tar -xzf ruby-*
cd ruby-*
./configure
make
sudo make install
sudo rm -rf ~/ruby-*

# install node
cd ~
wget --quiet https://nodejs.org/dist/v6.2.0/node-v6.2.0.tar.gz
tar -xzf node-v*
cd node-v*
./configure
make
sudo make install
sudo chmod 755 /usr/local/bin/node
sudo rm -rf ~/node-v*

# install postgres 9.5
cd ~
sudo touch /etc/apt/sources.list.d/pgdg.list
echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' | sudo tee -a /etc/apt/sources.list.d/pgdg.list
# sometimes this fails behind a proxy
# http://unix.stackexchange.com/a/82602
sudo -E wget --quiet https://www.postgresql.org/media/keys/ACCC4CF8.asc && break
# add the key
sudo -E apt-key add ACCC4CF8.asc
rm -f ACCC4CF8.asc

sudo apt-get -y update

sudo apt-get -y install postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libpq-dev postgresql-server-dev-9.5 expect

# Setup pg_hba.conf file so postgres can connect locally
sudo rm -f /etc/postgresql/9.5/main/pg_hba.conf

echo "# Administrative login with Unix domain sockets
local   all             postgres                                trust
local   all             vagrant                                 trust
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5" | sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf

# Reload postgres
sudo /etc/init.d/postgresql reload

# create a ubuntu user, for connecting locally if needed
sudo -u postgres createuser vagrant --createdb --no-superuser --no-createrole

# install redis
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
cd ~
wget http://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install
sudo mkdir -p /etc/redis

echo 'bind 127.0.0.1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised systemd
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes' | sudo tee -a /etc/redis/redis.conf

# This is already done, it seems, when installed
# echo '[Unit]
# Description=Redis In-Memory Data Store
# After=network.target
#
# [Service]
# User=redis
# Group=redis
# ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
# ExecStop=/usr/local/bin/redis-cli shutdown
# Restart=always
#
# [Install]
# WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/redis.service

# this is done also
# sudo adduser --system --group --no-create-home redis

# this is done also
# sudo mkdir -p /var/lib/redis

sudo chown redis:redis /var/lib/redis

sudo systemctl start redis
sudo rm -rf ~/redis-*

# install tmux
cd /home/vagrant
git clone https://github.com/tmux/tmux.git
# Dependencies were already installed in VM, but in case they weren't
# sudo apt-get -y install automake libevent-dev ncurses-dev
cd tmux
sh autogen.sh
./configure && make
sudo make install
sudo rm -rf /home/vagrant/tmux

# set ~/.gem as default gemhome/gempath for everyone
# you need to run sudo -E gem update --system
echo "gem: --no-doc
gemhome: ~/.gem
gempath: ~/.gem" | sudo tee -a /etc/gemrc

# never manually edit sudoers file
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="HTTP_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="HTTPS_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="NO_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="http_proxy"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="https_proxy"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="no_proxy"' /etc/sudoers

# make a consistent path experience, and make it work with the custom gem folder
sudo sed -i 's/:\/usr\/games:\/usr\/local\/games//' /etc/environment
sudo sed -i 's/PATH="\/usr/PATH="~\/.gem\/bin:\/usr/' /etc/environment
