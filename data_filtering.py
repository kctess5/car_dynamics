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

import yaml
import numpy as np

def dump_records(fn, records):
	with open(fn, 'w') as f:
		f.write(yaml.dump({'records': records}))

def fetch_records(fn):
	d = []
	with open(fn, 'r') as stream:
		try:
			return(yaml.load(stream)['records'])
		except yaml.YAMLError as exc:
			print(exc)

def centroid_deviation(track):
	centroids = np.array(map(lambda x: x['centroid'], track))
	centroid = np.mean(centroids, 0)
	deltas = centroids - centroid
	dists = np.sqrt(np.sum(deltas*deltas, 1))
	return np.std(dists) / np.mean(dists)
	
def frame_num_to_time(frame_num):
	return (frame_num-231.0) / 30.0 

def fix_frame_nums(frame):
	frame['frame_id'] = frame['frame_id'] + 31617

def make_constant_setting_tracks(track, regions):
	"""
	regions:
		- start (seconds)
		- end (seconds)
	track:
		[record]
	record:
		- frame_num (frames)
	"""

	region_map = {}

	for data_point in track:
		t = frame_num_to_time(data_point['frame_id'])

		for i in xrange(len(regions)):
			is_in_region = t > regions[i]['start'] and t < regions[i]['end']
			if is_in_region:
				if str(i) in region_map:
					region_map[str(i)].append(data_point)
				else:
					region_map[str(i)] = [data_point]
	results = []

	for k, v in region_map.iteritems():
		cr = regions[int(k)]
		results.append({
			"control_record": {
				"angle": cr['angle'],
				"speed": cr['speed'],
				"start": cr['start'],
				"end": cr['end']
			},
			"tracking_points": v
		})

	return results
	# 	print k, len(v)
	# return []
	# print region_map
		# r = filter(lambda x: t > x['start'] and t < x['end'], regions)
		
		# if not len(r):
		# 	continue



		# if r:
		# 	r = r[0]
		# print(r)

		# for region in regions:
		# 	if t > x['start'] and t < x['end']:

		# print t

FPS = 30
MIN_TRACK_LENGTH = FPS * 2 # min 5 seconds worth of tracking data

'''
This part combines the tracking and control data into contigous tracks
'''
# if __name__ == "__main__":
# 	# tracking_records = fetch_records("test.yaml")
# 	tracking_records = fetch_records("./tracking_data/combined_tracking_data.yaml")
# 	control_records = fetch_records("./control_data/filtered_control_log.yaml")
# 	# print(len(tracking_records), len(control_records))
	
# 	track_table = {}
# 	for record in tracking_records:
# 		k = str(int(record['id']))
# 		if k in track_table:
# 			track_table[k].append(record)
# 		else:
# 			track_table[k] = [record]

# 	segmented_data = []

# 	for track_id, tracking_records in track_table.iteritems():
# 		if len(tracking_records) > MIN_TRACK_LENGTH:
# 			segmented_data = segmented_data + make_constant_setting_tracks(tracking_records, control_records)

# 	for record in segmented_data:
# 		record['centroid_deviation_percentage'] = float(centroid_deviation(record['tracking_points']))
# 		record['num_points'] = len(record['tracking_points'])

# 	dump_records('constant_control_segments2.yaml', segmented_data)

def filter_segmented(record, max_deviation=0.13, min_points=100):
	return record['centroid_deviation_percentage'] < max_deviation and record['num_points'] > min_points

import matplotlib.mlab as mlab
import matplotlib.pyplot as plt

'''
This part removes data with large centroid variation
'''
if __name__ == "__main__":
	records = fetch_records("./constant_control_segments2.yaml")
	filtered_records = filter(filter_segmented, records)
	dump_records('filtered_constant_control_segments2.yaml', filtered_records)

# 	# mu, sigma = 100, 15
# 	# x = mu + sigma*np.random.randn(10000)

# 	# # the histogram of the data
# 	# n, bins, patches = plt.hist(deviations, 50, facecolor='green', alpha=0.75)

# 	# # # add a 'best fit' line
# 	# # y = mlab.normpdf( bins, mu, sigma)
# 	# # l = plt.plot(bins, y, 'r--', linewidth=1)

# 	# plt.xlabel('deviation_percentage')
# 	# plt.ylabel('num')
# 	# # plt.title(r'$\mathrm{Histogram\ of\ IQ:}\ \mu=100,\ \sigma=15$')
# 	# # plt.axis([40, 160, 0, 0.03])
# 	# plt.grid(True)

	# plt.show()