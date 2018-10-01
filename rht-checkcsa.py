#!/usr/bin/env python
#*-* coding: utf-8 *-*

import os
import subprocess


if  not os.system('ping -c 1 server0 &> /dev/null'):
    if not os.system('scp .checkcsa server0:/root/.checkcsa &> /dev/null'):
        mess = """
# Input(1):         check_all        完整测试(测试所有项)
# Input(ENTER):     check_no_user    部分测试(不包含用户密码的验证)

检查结果完全参照 RHCSA  ANSWER PDF
Please Input(1 or ENTER) : """
        print mess
        aList = subprocess.Popen('ssh server0 "python /root/.checkcsa"', shell=True,stdout=subprocess.PIPE).stdout.readlines()
        for i in aList:
            print i
        with open('/root/score-csa.txt', 'w') as f:
            f.writelines(aList)


    else:
        print  'Cat`t ssh server0 ,transfer script files failed'
        os._exit(2)
else:
    print 'Ping server0 failed'
    os._exit(1)

