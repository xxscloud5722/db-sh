
# centos cron

#start
systemctl start crond

#restart
systemctl restart crond

#edit
vim /etc/corntab

# 例子 每一小时 / 每6小时执行
# 0 */1 * * * root cd /opt/exec && ./x.sh 1
# 0 */6 * * * root cd /opt/exec && ./x.sh 2