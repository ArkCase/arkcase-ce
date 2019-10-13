#!/usr/bin/env bash
CATALINA_OPTS="-Xms1024m -Xmx2048m -Djavax.net.ssl.keyStorePassword=password -Djavax.net.ssl.trustStorePassword=password -Djavax.net.ssl.keyStore=/opt/common/arkcase.ks -Djavax.net.ssl.trustStore=/opt/common/arkcase.ts -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=50504 -Dcom.sun.management.jmxremote.rmi.port=50505 -Dcom.sun.management.jmxremote.authenticate=true -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname={{ internal_host }} -Dcom.sun.management.jmxremote.password.file=/opt/app/pentaho/password.file -Dcom.sun.management.jmxremote.access.file=/opt/app/pentaho/access.file -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"
export CATALINA_OPTS
export CATALINA_OUT=/opt/log/pentaho/catalina.out
export CATALINA_TMPDIR=/opt/tmp/pentaho
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
