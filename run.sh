#!/bin/bash

id -u 1000 2>/dev/null || useradd -M -s /bin/bash -u 1000 -g 1000 -G docker,sudo linuxbrew
chown linuxbrew:linuxbrew /home/linuxbrew
cd /home/linuxbrew
if ! test -e .linuxbrew/ok; then
    su -c "git clone https://github.com/Homebrew/linuxbrew.git /home/linuxbrew/.linuxbrew" - linuxbrew
    su -c "/home/linuxbrew/.linuxbrew/bin/brew update" - linuxbrew || su -c "/home/linuxbrew/.linuxbrew/bin/brew update" - linuxbrew
    su -c "/home/linuxbrew/.linuxbrew/bin/brew tap ambakshi/formulae" - linuxbrew
    su -c "/home/linuxbrew/.linuxbrew/bin/brew install brew-fpm" - linuxbrew
    su -c "/home/linuxbrew/.linuxbrew/Library/Homebrew/vendor/portable-ruby/2.3.3/bin/gem install --no-rdoc --no-ri fpm" - linuxbrew
    mkdir -p .local/bin bin
    ln -sfrn `pwd`/.linuxbrew/Library/Homebrew/vendor/portable-ruby/2.3.3/bin/fpm .local/bin/
    cp /etc/skel/.* .
    echo 'export HOMEBREW_BUILD_FROM_SOURCE=1' >> .bashrc
    echo 'export PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/bin:$PATH' >> .bashrc
    echo 'cd /home/linuxbrew' >> .bashrc
    chown -R linuxbrew:linuxbrew /home/linuxbrew
    touch .linuxbrew/ok
fi
/bin/bash -l
