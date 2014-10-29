
#!/usr/bin/env python

import os
import subprocess

sipp_exe = '/home/aawais/workspace/sipp/sipp'
saddr = '10.10.10.165'
sport1 = '5080'
sport2 = '5090'
em_wan = '10.10.10.82'
call_data = 'data_call.csv'
interface = '127.0.0.1:30000'
num_calls = '1'

def client_reinvite():
	uac_master = ' '.join([sipp_exe, '-i', saddr, '-p', sport1, '-m', num_calls, '-d 3000 -inf', call_data,
			'-3pcc', interface, '-sf uac_reinvite_master.sf', em_wan])
	uac_slave = ' '.join([sipp_exe, '-i', saddr, '-p', sport2, '-m', num_calls, '-inf', call_data,
			'-3pcc', interface, '-sf uac_reinvite_slave.sf', '-nd', em_wan])


	slave = subprocess.Popen(uac_slave, shell=True,
			stdin=subprocess.PIPE,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE
			)
	master = subprocess.Popen(uac_master, shell=True,
			stderr=subprocess.PIPE,
			stdin=subprocess.PIPE,
			stdout=subprocess.PIPE
			)


	master.wait()
	slave.wait()

	if master.returncode != 0 or slave.returncode != 0:
		return 1
	else:
		return 0


ret = client_reinvite()
if ret:
	print "failed"
else:
	print "success"





