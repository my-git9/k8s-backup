#!/bin/bash
BACKUP_DIR=/backup/component/$(date '+%Y%m%d')

BACKUP_time="`date +%Y%m%d-%H:%M:%S`"

BACKUP_tar="/backup/component/`date -d "3 days ago" +%Y%m%d`"

if [ ! -d "${BACKUP_DIR}" ];then
  mkdir -pv $BACKUP_DIR
fi
# 备份组件配置文件
back_component_conf(){
cp -r /etc/daocloud/dce  ${BACKUP_DIR}/dce_conf_backup_${BACKUP_time}
if [ $? -eq 0 ] ; then
 echo "back component_conf success ${BACKUP_time}" >>${BACKUP_DIR}/back_component_conf.log
fi
}

# 备份组件数据
back_component_data(){
# engine 数据
cp -r /var/local/dce/engine  ${BACKUP_DIR}/dce_engine_data_backup_${BACKUP_time}

if [ $? -eq 0 ] ; then
 echo "back component_data engine success ${BACKUP_time}" >>${BACKUP_DIR}/back_component_conf.log
fi

# parcel 数据
cp -r /var/local/dce/parcel  ${BACKUP_DIR}/dce_parcel_data_backup_${BACKUP_time}

if [ $? -eq 0 ] ; then
 echo "back component_data parcel success ${BACKUP_time}" >> ${BACKUP_DIR}/back_component_conf.log
fi
}

# 默认归档3天前的备份配置,可根据实际情况调整
back_tar(){
tar zcvf ${BACKUP_tar}.tar.gz  ${BACKUP_tar}
mv ${BACKUP_tar} /tmp/
}

# 删除30 天前数据，可根据实际情况调整
delete_tar(){
find /backup/component/ -name "*.gz" -mtime +30 -exec rm -f {} \;
}
main(){
back_component_conf
back_component_data
back_tar
delete_tar
}
main