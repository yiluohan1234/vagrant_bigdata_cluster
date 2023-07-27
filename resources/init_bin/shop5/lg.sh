#!/bin/bash
for i in hdp101 hdp102; do
    echo "========== $i =========="
    ssh $i "source /etc/profile; cd /opt/module/dataware/log; java -jar gmall2020-mock-log-2021-10-10.jar >/dev/null 2>&1 &"
done
