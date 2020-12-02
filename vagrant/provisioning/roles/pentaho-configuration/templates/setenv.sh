#!/usr/bin/env bash
export CATALINA_OUT={{ root_folder }}/log/pentaho/catalina.out
export CATALINA_TMPDIR={{ root_folder }}/tmp/pentaho
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
