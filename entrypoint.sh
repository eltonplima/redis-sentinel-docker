#!/bin/sh

SENTINEL_CHECK_DELAY=${SENTINEL_CHECK_DELAY:-1}

###############################################################################
# The code bellow is used as workaround to set REDIS_HOST using redis sentinel.
###############################################################################
if [ -n "${REDIS_HOST}" ]
then
    echo "We are not using redis sentinel because REDIS_HOST is set."
    echo "The redis server address is: " ${REDIS_HOST}
    echo "Starting services..."
    sed -i "s@REDIS_HOST=\"localhost\"@REDIS_HOST=\"$REDIS_HOST\"@g" $HOME/supervisord.conf
    /usr/local/bin/supervisord -c $HOME/supervisord.conf
else
    if [ -n "${SENTINEL_HOST}" ]
    then
        REDIS_HOST=`redis-cli -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --raw SENTINEL masters | grep ip -A 1 | grep -v ip`

        if [ -n "${REDIS_HOST}" ]
        then
            echo "The redis master address is: " ${REDIS_HOST}
            echo "Starting services..."
            sed -i "s@REDIS_HOST=\"localhost\"@REDIS_HOST=\"$REDIS_HOST\"@g" $HOME/supervisord.conf
            /usr/local/bin/supervisord -c $HOME/supervisord.conf&
        else
            echo "Redis master not found!"
            exit 1
        fi

        # We ask sentinel about new master on every $SENTINEL_CHECK_DELAY
        while true; do
            NEW_MASTER=`redis-cli -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --raw SENTINEL masters | grep ip -A 1 | grep -v ip`
            if [ "${REDIS_HOST}" != "${NEW_MASTER}" ]
            then
                echo "Change redis master: " ${REDIS_HOST} "=>" ${NEW_MASTER}
                sed -i "s@REDIS_HOST=\"$REDIS_HOST\"@REDIS_HOST=\"$NEW_MASTER\"@g" $HOME/supervisord.conf
                REDIS_HOST=$NEW_MASTER
                supervisorctl reload
                echo "Restarting services"
                supervisorctl restart all
            fi
            sleep ${SENTINEL_CHECK_DELAY}
        done
    else
        echo "SENTINEL_HOST is not defined."
        exit 1
    fi
fi
