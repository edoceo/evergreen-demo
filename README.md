
## Tricking PostgreSQL

This little trick was put into /etc/conf.d/postgresql-9.1

    echo $(( $(awk '/MemTotal/ { print $2 }' /proc/meminfo) * 1024 / 2 )) > /proc/sys/kernel/shmmax
    
    
# Updating the Evergreen Demo

* Stop all services
* ./update.sh
* ./update-opensrf.sh
* ./update-ejabberd.sh
* ./update-apache.sh

## Adding Demo Data

* ./update-demodata.sh

## Try a Telnet Client?

* http://git.mvlcstaff.org/?p=jason/issa.git;a=summary