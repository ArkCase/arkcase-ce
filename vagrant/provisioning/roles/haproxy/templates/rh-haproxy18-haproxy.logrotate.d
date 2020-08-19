{{ root_folder }}/log/haproxy/*.log {
  copytruncate
  daily
  rotate 7
  compress
  missingok
  size 10k
  dateext
  dateyesterday
}
