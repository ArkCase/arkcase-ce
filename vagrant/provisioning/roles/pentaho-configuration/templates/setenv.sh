#!/usr/bin/env bash
CATALINA_OPTS="-Xms1024m -Xmx2048m -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=50504 -Dcom.sun.management.jmxremote.rmi.port=50505 -Dcom.sun.management.jmxremote.authenticate=true -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname={{ internal_host }} -Dcom.sun.management.jmxremote.password.file={{ root_folder }}/app/pentaho/password.file -Dcom.sun.management.jmxremote.access.file={{ root_folder }}/app/pentaho/access.file -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dcom.redhat.fips=false"
export CATALINA_OPTS
export CATALINA_OUT={{ root_folder }}/log/pentaho/catalina.out
export CATALINA_TMPDIR={{ root_folder }}/tmp/pentaho
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
