#!/bin/bash
ssh hadoop102 "source /etc/profile; cd /opt/module/dataware/db; java -jar gmall2020-mock-db-2021-11-14.jar >/dev/null 2>&1 &"
