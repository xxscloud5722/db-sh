# shellcheck disable=SC2209
DATA_STRING=$(date +'%F %H:%m:%S')
ID=$(date +'%F_%H_%m_%S')

# MySQL Conf
MYSQL_USER=""
MYSQL_PASSWORD=""
MYSQL_HOST=""
MYSQL_PORT=""
MYSQL_DB=""

# Mongo Conf
MONGO_USER=""
MONGO_PASSWORD=""
MONGO_AUTH_DB=""
MONGO_HOST=""
MONGO_PORT=""
MONGO_DB=""

# GIT
GIT_URLS=""

# shellcheck disable=SC1009
function exec(){
echo "$1"
if ! $1; then echo "command failed"; exit 1; fi
}

function x_check(){
  echo "========检查配置========"
  echo "MYSQL_USER:$MYSQL_USER MYSQL_PASSWORD:$MYSQL_PASSWORD MYSQL_DB:$MYSQL_DB"
  echo "-----------------------"
  echo "MONGO_USER:$MONGO_USER MONGO_PASSWORD:$MONGO_PASSWORD MONGO_AUTH_DB:$MONGO_AUTH_DB MONGO_DB:$MONGO_DB"
  echo "-----------------------"
  echo "GIT: $GIT_URLS"
  echo "======================="
}

function x_mysql() {
  echo "=====备份MySQL数据库====="
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `mkdir ./mysql_"${ID}"`
  # shellcheck disable=SC2006
  # shellcheck disable=SC2001
  for item  in `echo ${MYSQL_DB} | sed 's/,/ /g'`
  do
    echo "开始备份数据库: $item"
    # shellcheck disable=SC2046
    exec `docker run --rm mysql:8.0.22 mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h "${MYSQL_HOST}" -P"${MYSQL_PORT}" --skip-opt "${item}" > ./mysql_"${ID}"/"${item}".sql`
  done
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  7za a ./mysql_"${ID}".7z ./mysql_"${ID}"/
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  mv ./mysql_"${ID}".7z /mnt/mysql_"${ID}".7z
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `rm -rf ./mysql_"${ID}"`
  echo "======================="
}

function x_mongo() {
  echo "=====备份Mongo数据库====="
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `mkdir ./mongo_"${ID}" && chmod 777 ./mongo_"${ID}"`
  # shellcheck disable=SC2001
  # shellcheck disable=SC2006
  for item  in `echo ${MONGO_DB} | sed 's/,/ /g'`
  do
    echo "开始备份数据库: $item"
    # shellcheck disable=SC2046
    exec `docker run --rm -v /opt/exec/mongo_"${ID}":/opt/exec/mongo_"${ID}" mongo:4.2-bionic mongodump -h "${MONGO_HOST}":"${MONGO_PORT}" -d "${item}" -u "${MONGO_USER}" -p "${MONGO_PASSWORD}" --authenticationDatabase "${MONGO_AUTH_DB}" -o ./opt/exec/mongo_"${ID}"`
  done
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  7za a mongo_"${ID}".7z ./mongo_"${ID}"/
  mv ./mongo_"${ID}".7z /mnt/mongo_"${ID}".7z
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `rm -rf ./mongo_"${ID}"`
  echo "========================"
}

function x_code() {
  echo "=====备份Code仓库====="
  # shellcheck disable=SC2093
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `rm -rf ./code`
  # shellcheck disable=SC2046
  # shellcheck disable=SC2006
  exec `mkdir ./code`
  # shellcheck disable=SC2001
  # shellcheck disable=SC2006
  for item  in `echo ${GIT_URLS} | sed 's/,/ /g'`
  do
    echo "开始备份代码: $item"
  done
  echo "====================="
}

function destroy() {
  echo "确认执行 《毁灭》 命令吗? 确认输入 1"
  # shellcheck disable=SC2162
  read NUMBER
  if [ "${NUMBER}" -eq "1" ]; then
      # shellcheck disable=SC2093
      # shellcheck disable=SC2093
      exec x_mysql
      # shellcheck disable=SC2093
      exec x_mongo
      # shellcheck disable=SC2093
      exec x_code
      echo "=====开始执行毁灭====="
      #SELECT concat('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema = '数据库';
      # shellcheck disable=SC2001
      # shellcheck disable=SC2006
      for item  in `echo ${MYSQL_DB} | sed 's/,/ /g'`
      do
        echo "毁灭数据库: $item"
      done
      echo "====================="
  else
    echo "程序结束"
    exit 0
  fi
}


# shellcheck disable=SC2120
function main() {
clear
# shellcheck disable=SC2093
# exec ls -all
VERSION="1.0"
echo "=====备份脚本====="
echo "当前版本: ${VERSION}"
# shellcheck disable=SC2154
echo "当前系统时间: ${DATA_STRING}"
echo "0) 检查环境"
echo "1) 手动备份MySQL数据库"
echo "2) 手动备份Mongo数据库"
echo "3) 手动备份代码"
echo "9) 毁灭!!"
echo "================="
echo "请输入编号___"
# shellcheck disable=SC2162
# shellcheck disable=SC2034
read NUMBER
echo "输入的编号是_${NUMBER}"
echo "任意键继续"
# shellcheck disable=SC2162
# shellcheck disable=SC2034
read ENT
if [ "${NUMBER}" -eq "0" ]; then
  exec x_check
elif [ "${NUMBER}" -eq "1" ]; then
  exec x_mysql
elif [ "${NUMBER}" -eq "2" ]; then
  exec x_mongo
elif [ "${NUMBER}" -eq "3" ]; then
  exec x_code
elif [ "${NUMBER}" -eq "9" ]; then
  exec destroy
else
  echo "输入错误, 程序结束"
  exit 0
fi
}



# Start Application

# shellcheck disable=SC2170
if [ "${1}" -eq "1" ]; then
  echo "当前系统时间: ${DATA_STRING}"
  exec x_mysql
elif [ "${1}" -eq "2" ]; then
  echo "当前系统时间: ${DATA_STRING}"
  exec x_mongo
elif [ "${1}" -eq "3" ]; then
  echo "当前系统时间: ${DATA_STRING}"
  exec x_code
else
  main
fi