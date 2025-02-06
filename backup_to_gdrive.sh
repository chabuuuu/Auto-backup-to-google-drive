#!/bin/bash

# Load biến môi trường từ file .env
source .env

DATE=$(date +"%Y%m%d_%H%M%S")

MYSQL_BACKUP_FILE="$BACKUP_DIR/mysql_backup_$DATE.sql"
# REDIS_BACKUP_FILE="$BACKUP_DIR/redis_backup_$DATE.rdb"

# Hàm gửi thông báo đến Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$message"
}

# Tạo thư mục backup nếu chưa có
mkdir -p $BACKUP_DIR

# Backup MySQL
# Backup MySQL
if mysqldump -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS --databases $DB_NAME >$MYSQL_BACKUP_FILE; then
    echo "MySQL backup successful."
else
    send_telegram_message "⚠️ Backup thất bại! Không thể sao lưu MySQL."
    exit 1
fi

# Backup Redis
# redis-cli SAVE
# cp /var/lib/redis/dump.rdb $REDIS_BACKUP_FILE

# Upload lên Google Drive
if rclone copy $MYSQL_BACKUP_FILE $GDRIVE_FOLDER; then
    send_telegram_message "✅ Backup MySQL thành công! File: mysql_backup_$DATE.sql đã được upload lên Google Drive."
else
    send_telegram_message "❌ Backup thành công nhưng upload lên Google Drive thất bại!"
    exit 1
fi
# rclone copy $REDIS_BACKUP_FILE $GDRIVE_FOLDER

# Xóa file cũ hơn 7 ngày trên máy
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -delete
# find $BACKUP_DIR -type f -name "*.rdb" -mtime +7 -delete

# Xóa file cũ hơn 30 ngày trên Google Drive
if rclone delete $GDRIVE_FOLDER --min-age 30d; then
    send_telegram_message "✅ Đã tự động xóa thành công các file backup cũ hơn 30 ngày trên Google Drive."
else
    send_telegram_message "❌ Xóa tự động các file backup cũ hơn 30 ngày trên Google Drive thất bại!"
    exit 1
fi

echo "Backup completed and uploaded to Google Drive."
