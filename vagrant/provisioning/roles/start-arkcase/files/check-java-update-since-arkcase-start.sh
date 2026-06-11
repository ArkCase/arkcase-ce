#!/bin/bash
ARKCASE_PID=$(systemctl status arkcase | grep "Main PID" | awk '{ print $3 }')
if [[ "" == "$ARKCASE_PID" ]]; then
  echo "ArkCase not running, exiting"
  exit 1
fi
JAVA_HOME=$(xargs -0 -L1 -a /proc/"$ARKCASE_PID"/environ | grep JAVA_HOME | sed s.JAVA_HOME=..)
JDK_TIMEZONE_UPDATE=$(stat "$JAVA_HOME"/jre/lib/tzdb.dat | grep Change | sed s/"Change: "// | grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2} [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}')
ARKCASE_START_TIME=$(systemctl status arkcase | grep Active | grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2} [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}')
if [[ "$JDK_TIMEZONE_UPDATE" > "$ARKCASE_START_TIME" ]]; then
  echo "Restarting ArkCase"
  systemctl restart arkcase
fi

