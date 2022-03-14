#!/bin/bash
##this script will check all of the components that are required for ArkCase to work on developer VM
##if the services are not running it will start the services

##list the services to check
SERVICES=('haproxy' 'config-server' 'mariadb' 'httpd' 'pentaho' 'snowbound' 'solr' 'alfresco' 'activemq' 'confluent-kafka' 'confluent-zookeeper' 'confluent-control-center' 'confluent-kafka-connect' 'confluent-kafka-rest' 'confluent-ksql' 'confluent-kafka-connect' 'confluent-schema-registry' 'mongod' 'samba' 'alfresco7')

 for i in "${SERVICES[@]}"
  do
    echo $i

    systemctl is-active $i
    STATS=$(echo $?)

    systemctl list-unit-files --all | grep $i
    ISSERVICE=$(echo $?)

    ###If service is not running and is inactive####
    if [[ $STATS -ne "0" ]] && [[ $ISSERVICE -eq '' ]]
        then
        ##TRY TO RESTART THE SERVICE###
        systemctl start $i
    fi
  done