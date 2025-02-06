#!/bin/bash

# Load biến môi trường từ file .env
source .env

DATE=$(date +"%Y%m%d_%H%M%S")

MYSQL_BACKUP_FILE="$BACKUP_DIR/mysql_backup_$DATE.sql"
# REDIS_BACKUP_FILE="$BACKUP_DIR/redis_backup_$DATE.rdb"

# Tạo thư mục backup nếu chưa có
mkdir -p $BACKUP_DIR

# Backup MySQL
mysqldump -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS --databases $DB_NAME >$MYSQL_BACKUP_FILE

# Backup Redis
# redis-cli SAVE
# cp /var/lib/redis/dump.rdb $REDIS_BACKUP_FILE

# Upload lên Google Drive
rclone copy $MYSQL_BACKUP_FILE $GDRIVE_FOLDER
# rclone copy $REDIS_BACKUP_FILE $GDRIVE_FOLDER

# Xóa file cũ hơn 7 ngày trên máy
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -delete
# find $BACKUP_DIR -type f -name "*.rdb" -mtime +7 -delete

# Xóa file cũ hơn 30 ngày trên Google Drive
rclone delete $GDRIVE_FOLDER --min-age 30d

echo "Backup completed and uploaded to Google Drive."
