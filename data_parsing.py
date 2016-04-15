# load data from file and parse into data structures

# filter tracks by various metrics
# 	- bounding box size limitations
#   - Std deviation from centroid of all tracking points

# continuously constant car settings

# {initial tracks} -> {car tracks *save*} -> {car tracks with constant settings}


# want: arc radius, effective steering angle, effective speed, steering angle, speed setting

# separate an array of long, valid tracks of cars
# use a sliding window with some stride to collect a set of metrics for each data point

"""
data:
	track id, frame id, position, bounding_box

car tracks	
	[data]
""" 

import re, yaml
import ast

non_decimal = re.compile(r'[^\d.]+')

def make_records(string):
	d = string.splitlines()
	frame_num = int(non_decimal.sub('', d[0]))

	def extract_arr(name):
		arr = filter(lambda x: name in x, d)
		arr = map(lambda x: x[len(name)+1:], arr)
		arr = map(lambda x: ast.literal_eval(x), arr)
		return arr

	centroids = extract_arr("centroid")
	bboxes = extract_arr("bbox")
	ids = filter(lambda x: "id" in x and not "centroid" in x, d)
	ids = map(lambda x: float(non_decimal.sub('', x)), ids)

	records = zip(ids, centroids, bboxes)

	def make_record(raw_record):
		return {
			"frame_id": frame_num,
			"id": raw_record[0],
			"centroid": raw_record[1],
			"bbox": raw_record[2]
		}

	return map(make_record, records)

if __name__ == "__main__":
	string_data = []

	with open('video1_tracking_data.txt', 'r') as f:
		string_data = f.read().split("frame_number")

	string_data = filter(lambda x: "id" in x, string_data)
	records = reduce(lambda x,y: x+y, map(lambda x: make_records(x), string_data))
	
	with open("video1_data.yaml", 'w') as f:
		f.write(yaml.dump(records))
