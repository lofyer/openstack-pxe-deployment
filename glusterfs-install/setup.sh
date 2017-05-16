#!/bin/bash
systemctl enable glusterd glusterfsd
systemctl start glusterd glusterfsd

gluster peer add ZZZ
