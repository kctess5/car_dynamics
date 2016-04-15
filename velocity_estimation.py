"""
data:
	track id, frame id, position, bounding_box

car tracks	
	[data]
""" 

import yaml
import numpy as np
import fit_circle

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

def filter_segmented(record, max_deviation=0.13, min_points=100):
	return record['centroid_deviation_percentage'] < max_deviation and record['num_points'] > min_points

def fit_circles(record):
	x = np.array(map(lambda x: x['centroid'][0] , record['tracking_points']))
	y = np.array(map(lambda x: x['centroid'][1] , record['tracking_points']))

	min_samples = 40
	stride = 100
	width = 200
	pos = 0

	# print
	# print len(record['tracking_points'])
	d = []
	while x.size - pos > min_samples:
		end_ind = pos + min(x.size - pos, width)
		x_data = x[pos:end_ind]
		y_data = y[pos:end_ind]

		d.append(fit_circle.fit_leastsq_jacobian(x_data,y_data))
		pos += stride

	radii = np.array(map(lambda x: x['radius'], d))
	centers = map(lambda x: x['center'], d)
	radius = np.mean(radii)
	radial_deviation = np.std(radii)

	record['turn_radius'] = float(np.mean(radii))
	if len(radii) > 1:
		record['turn_radius_deviation'] = float(np.std(radii))
	else:
		record['turn_radius_deviation'] = -1.0
	record['turn_centers'] = centers
	record['turn_radius_computation_stride'] = stride
	record['turn_radius_computation_width'] = width

def cart2pol(x, y):
    rho = np.sqrt(x**2 + y**2)
    phi = np.arctan2(y, x)
    return(rho, phi)

import math

def estimate_velocity(record):
	print
	print
	stride = record['turn_radius_computation_stride']
	width = record['turn_radius_computation_width']
	centers = record['turn_centers']
	points = record['tracking_points']

	pos = 0
	num_strides = 0
	center = centers[0]

	thetas = []
	times = []
	for i in xrange(len(points)):
		p = points[i]['centroid']
		r, theta = cart2pol(p[0] - center[0], p[1] - center[1])
		t = frame_num_to_time(points[i]['frame_id'])
		thetas.append(theta)
		times.append(t)

		if i % stride == 0 and not i == 0:
			num_strides = min(len(centers)-1, num_strides+1)
			center = centers[num_strides]

	dts = []
	dthetas = []
	angular_velocities = []

	for i in xrange(len(thetas)-2):
		dt = times[i+1] - times[i]
		dtheta = (thetas[i+1] - thetas[i]) % (2*math.pi)
		angular_velocity = dtheta / dt

		# print dtheta, dt, angular_velocity

		dts.append(dt)
		dthetas.append(dtheta)
		angular_velocities.append(angular_velocity)

	record['median_angular_velocity'] = np.median(angular_velocities)
	record['mean_angular_velocity'] = np.mean(angular_velocities)
	record['stdev_angular_velocity'] = np.std(angular_velocities)

import matplotlib.mlab as mlab
import matplotlib.pyplot as plt

def make_sparse_data(record):
	return [record['control_record']['angle'], record['control_record']['speed'], record['turn_radius']]

if __name__ == "__main__":
	# records = fetch_records("./filtered_constant_control_segments.yaml")
	# map(fit_circles, records)
	# dump_records("./filtered_constant_control_segments_fit_circles.yaml", records)

	records = fetch_records("./filtered_constant_control_segments_fit_circles.yaml")
	# records = fetch_records("./test.yaml")
	map(estimate_velocity, records)
	dump_records("./filtered_constant_control_segments_fit_circles_velocity.yaml", records)
