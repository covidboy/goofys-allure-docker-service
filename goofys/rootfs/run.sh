#!/bin/bash
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
syslog-ng -f /etc/syslog-ng/syslog-ng.conf

echo -e "${ORANGE}Mounting Bucket ${BUCKET} to ${MOUNT_DIR}"

[[ "$UID" -ne "0" ]] && MOUNT_ACCESS="allow_other" || MOUNT_ACCESS="nonempty"

goofys -f ${ENDPOINT:+--endpoint $ENDPOINT} --region $REGION --stat-cache-ttl $STAT_CACHE_TTL --type-cache-ttl $TYPE_CACHE_TTL --dir-mode $DIR_MODE --file-mode $FILE_MODE --uid $UID --gid $GID -o $MOUNT_ACCESS $BUCKET $MOUNT_DIR
echo "exit status - mounting done"
