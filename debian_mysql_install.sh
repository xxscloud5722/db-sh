groupadd mysql
useradd -r -g mysql mysql

# 脚本出错时终止执行
set -e

# shellcheck disable=SC2236
if [ ! -n "${1}" ]; then
  echo "请输入数据库版本"
  exit 1
fi

# shellcheck disable=SC2236
if [ ! -n "${2}" ]; then
  echo "请输入MySQL 安装路径"
  exit 1
fi

# shellcheck disable=SC2236
if [ ! -n "${3}" ]; then
  echo "请输入MySQL 数据存放路径"
  exit 1
fi

echo '安装数据库版本: '"${1}"
echo 'MySQL 安装路径:'"${2}"
echo 'MySQL 数据目录: '"${3}"

# 创建目录
mkdir -p "${2}"
mkdir -p "${3}"

#判断是否有输入的值
echo '安装基础组件...'
apt install libaio1 wget vim -y && apt update

echo '----- 系统信息 -----'
uname -a && cat /proc/version && cat /etc/issue &&
lscpu &&
cat /proc/meminfo
echo '-------------------'

echo '----- swap 关闭 -----'
swapoff -a && sed -ri 's/.*swap.*/#&/' /etc/fstab
echo 'swap success'
echo '-------------------'

echo '----- 查看磁盘 -----'
df -hT
echo '确保磁盘是ext4或者xfs文件系统！！'
echo '-------------------'

echo '----- 关闭SELINUX -----'
# shellcheck disable=SC2034
SELINUX=disabled
echo 'SELINUX disabled'
echo '-------------------'

echo '下载由七牛云提供，七牛云就是便宜!'
echo '下载 Mysql_'"${1}"''
wget http://devops.xxscloud.com/mysql-"${1}"-linux-glibc2.17-x86_64-minimal.tar

echo '下载 XtraBackup'
wget http://devops.xxscloud.com/percona-xtrabackup-"${1}"-15-Linux-x86_64.glibc2.17.tar.gz

echo '下载 Percona-Toolkit'
wget http://devops.xxscloud.com/percona-toolkit-3.3.0_x86_64.tar.gz

echo '安装 Mysql_'"${1}"''
tar -xvf ./mysql-"${1}"-linux-glibc2.17-x86_64-minimal.tar
tar -xvf ./mysql-"${1}"-linux-glibc2.17-x86_64-minimal.tar.xz

echo '安装 XtraBackup'
tar -xvf percona-xtrabackup-"${1}"-15-Linux-x86_64.glibc2.17.tar.gz
mv ./percona-xtrabackup-"${1}"-15-Linux-x86_64.glibc2.17 ./xtrabackup
mv ./xtrabackup ./mysql-"${1}"-linux-glibc2.17-x86_64-minimal/

echo '安装 Percona-Toolkit'
tar -xvf percona-toolkit-3.3.0_x86_64.tar.gz
mv ./percona-toolkit-3.3.0 ./percona-toolkit
mv ./percona-toolkit ./mysql-"${1}"-linux-glibc2.17-x86_64-minimal/

mv ./mysql-"${1}"-linux-glibc2.17-x86_64-minimal/* "${2}"/


echo '生产 Mysql_'"${1}"' 配置文件'
# shellcheck disable=SC2086
mkdir -p ${2}/log
cat <<EOF > "${2}"/my.cnf
[client]
port = 3306
socket = ${1}/mysql.sock

[mysqld]
server-id = 1
port = 3306
basedir = ${2}
datadir = ${3}
pid-file = ${2}/mysql.pid
socket = ${2}/mysql.sock
tmpdir = /tmp
bind-address = 0.0.0.0

user = mysql
skip_name_resolve = 1
transaction_isolation = READ-COMMITTED

character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
init_connect='SET NAMES utf8mb4'
lower_case_table_names = 1
max_connections = 500
max_connect_errors = 1000
explicit_defaults_for_timestamp = true
max_allowed_packet = 128M
interactive_timeout = 1800
wait_timeout = 1800
log_error = ${2}/log/mysql.log

# 跳过密码登录
# skip-grant-tables
EOF

echo '配置 Mysql_'"${1}"'目录'
chown -R mysql:mysql "${2}"/
chown -R mysql:mysql "${2}"/*
chown -R mysql:mysql "${3}"

echo '初始化MySQL Data'
"${2}"/bin/mysqld --defaults-file="${2}"/my.cnf --initialize --lower-case-table-names=1

echo 'MySQL Password'
grep 'temporary password' "${2}"/log/mysql.log



# 输出启动MySQL脚本
echo '输出脚本文件...'

cat <<EOF > "${2}"/start.sh
nohup ${2}/bin/mysqld --defaults-file=${2}/my.cnf >/dev/null 2>&1 &
EOF

cat <<EOF > "${2}"/stop.sh
${2}/bin/mysqladmin -uroot -p shutdown --socket=${2}/mysql.sock
EOF

cat <<EOF > "${2}"/restart.sh
${2}/stop.sh && ${2}/start.sh
EOF

echo '赋予权限...'
chmod +x "${2}"/start.sh && chmod +x "${2}"/stop.sh && chmod +x "${2}"/restart.sh
echo '启动数据库...'
"${2}"/start.sh