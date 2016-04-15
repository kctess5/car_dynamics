lens_correction.m can be used with minor modifications to remove GoPro Hero's lens distortion, and then apply a projective transformation to a video to make the pixels coorespond with real world data. Make sure to have measurements of the various features in your video so that you can calibrate the system and test that it is accurately mapping space.

Notes:
	- you will have to add ./lensdistort/lensdistort/ to your matlab path to deskew video
	- input files located in ./raw_video
	- outputs .avi files to ./lens_corrected
	- when the picture window appears at first, click the corners of a known rectangle in clockwise order starting from the lower left
	- adjust the side_len, left_padding, top_padding variables to change positioning of the frame relative to the known rectangle

car_extraction.m is used to find the center point of the racecar for each frame, and visually estimate the heading of the car.

data_parsing.py is used to extract raw camera data from badly formatted Matlab log files and spit the result into yaml

data_filtering.py is used to filter and combine the tracking and control data

extract_control.py was used to extract raw control data from badly formatted Python log files into useful YAML

time_align.m is a simple helper file to help lining up the video to the control data

circle_fitting.py fits circles to the filtered path data
fit_circle.py contains least squares optimization functions used in circle_fitting.py

velocity_estimation.py is used to compute velocity from video tracking information