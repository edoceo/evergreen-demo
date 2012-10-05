
## Tricking PostgreSQL

This little trick was put into /etc/conf.d/postgresql-9.1

    echo $(( $(awk '/MemTotal/ { print $2 }' /proc/meminfo) * 1024 / 2 )) > /proc/sys/kernel/shmmax