tail -n 0 -F /opt/app/acm/arkcase/apache-tomcat-9.0.8/logs/catalina.out | awk '
		/INFO/ {system("echo INFO DETECTED") }
		/Some other Error Message.../ {system("echo INFO DETECTED") }'
