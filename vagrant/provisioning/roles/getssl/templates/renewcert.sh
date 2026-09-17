#!/bin/bash
cd {{ root_folder }}/getssl ; python3 -m http.server 8888 &
{{ root_folder }}/getssl/getssl -d -u -a
[[ -f /etc/pki/tls/certs/{{ external_host }}.pem ]] && cp /etc/pki/tls/certs/{{ external_host }}.pem /etc/pki/tls/certs/{{ external_host }}.pem.old
cat /root/.getssl/{{ external_host }}/fullchain.crt /root/.getssl/{{ external_host }}/{{ external_host }}.key > /etc/pki/tls/certs/{{ external_host }}.pem
systemctl reload haproxy
ps -ef | grep http.server | grep python | awk '{ print $2 }' | xargs kill -9
