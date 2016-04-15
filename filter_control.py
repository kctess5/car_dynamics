"""
data:
	track id, frame id, position, bounding_box

car tracks	
	[data]
""" 

import yaml
import numpy as np

def fetch_records(fn):
	d = []
	with open(fn, 'r') as stream:
		try:
			return(yaml.load(stream)['records'])
		except yaml.YAMLError as exc:
			print(exc)

MIN_T = 5 # seconds

def dump_records(fn, records):
	with open(fn, 'w') as f:
		f.write(yaml.dump({'records': records}))

if __name__ == "__main__":
	records = fetch_records("control_log.yaml")

	# print len(records)
	# for i in xrange(1,15):
	# 	print len(filter(lambda x: x['end'] - x['start'] > i, records))
	# 	pass

	# print(len(records))
	records = filter(lambda x: x['end'] - x['start'] > MIN_T, records)
	dump_records('filtered_control_log.yaml', records)
	# print(len(records))
	# # print(records)