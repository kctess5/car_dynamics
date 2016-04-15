"""
extract:
	constant control regions 
	time ranges from beginning to end
"""
import yaml

def extract_speed(line):
	return float(line.split('to:(', 1)[-1].split(',')[0])

def extract_angle(line):
	return float(line.split(', ', 1)[-1].split(')at')[0])

def extract_time(line):
	return float(line.split('t=', 1)[-1])

if __name__ == "__main__":
	string_data = []
	with open('./control_log.txt') as f:
	    text = f.read()
	    string_data = text.splitlines()

	string_data = filter(lambda x: " t=" in x, string_data)
	state_regions = []

	for i in xrange(len(string_data)-1):
		if "Changed drive state to" in string_data[i]:
			state_region = {}
			state_region['speed'] = extract_speed(string_data[i])
			state_region['angle'] = extract_angle(string_data[i])
			state_region['start'] = extract_time(string_data[i])
			state_region['end'] = extract_time(string_data[i+1])
			state_regions.append(state_region)

	min_t = min(map(lambda x: x['start'], state_regions))
	
	def normalize_times(sr):
		sr['start'] = sr['start'] - min_t
		sr['end'] = sr['end'] - min_t

	map(normalize_times, state_regions)

	with open("control_log.yaml", 'w') as f:
		f.write(yaml.dump({'records': state_regions}))