tail -n 0 -F /opt/app/acm/arkcase/apache-tomcat-9.0.8/logs/catalina.out | awk '
		/Hazelcast\ instance\ is\ not\ active/ {system("systemctl restart arkcase") }
		/java\.lang\.OutOfMemoryError/ {system("systemctl restart arkcase") }'
