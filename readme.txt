lens_correction.m can be used with minor modifications to remove GoPro Hero's lens distortion, and then apply a projective transformation to a video to make the pixels coorespond with real world data. Make sure to have measurements of the various features in your video so that you can calibrate the system and test that it is accurately mapping space.

Notes:
	- you will have to add ./lensdistort/lensdistort/ to your matlab path to deskew video
	- input files located in ./raw_video
	- outputs .avi files to ./lens_corrected
	- when the picture window appears at first, click the corners of a known rectangle in clockwise order starting from the lower left
	- adjust the side_len, left_padding, top_padding variables to change positioning of the frame relative to the known rectangle

car_extraction.m is used to find the center point of the racecar for each frame, and visually estimate the heading of the car.

useful info:
	frame number
	framerate
	video file
	tracking id
	bbox
	