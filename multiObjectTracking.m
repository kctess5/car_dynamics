%close all;
% clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % load car data so we don't overwrite anything
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% car_data = YAML.read('./car_data/video2_data.yaml')

% % read video from file
% reader = VideoReader('./lens_corrected/video2.avi');
% numframes = reader.NumberOfFrames;
% test_frame = read(reader, 770);
% grey_test_frame = rgb2gray(test_frame);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % load car data so we don't overwrite anything
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function multiObjectTracking(video_file_name, frame_range)

	% Create System objects used for reading video, detecting moving objects,
	% and displaying the results.
	obj = setupSystemObjects(video_file_name);
	log_file = fopen('log.txt','a');


	tracks = initializeTracks(); % Create an empty array of tracks.
	% frame_ind = frame_range(1);
	frame_ind = 1;

	nextId = 1; % ID of the next track

	% Detect moving objects, and track them across video frames.
	% while ~isDone(obj.reader)
	for ind = 28125:obj.reader.NumberOfFrames-1
	%for ind = frame_range
		frame_ind = ind;
		frame = readFrame(ind);
		[centroids, bboxes, mask] = detectObjects(frame);
		predictNewLocationsOfTracks();
		[assignments, unassignedTracks, unassignedDetections] = ...
			detectionToTrackAssignment();

		updateAssignedTracks();
		updateUnassignedTracks();
		deleteLostTracks();
		createNewTracks();

		displayTrackingResults();
	end

	fclose(log_file);

	function flog(string)
		% fprintf(log_file, '\n\n\n[more_data]\n');
		fprintf(log_file, strcat(string,'\n'));
	end


	function obj = setupSystemObjects(video_file)
		% Initialize Video I/O
		% Create objects for reading a video from a file, drawing the tracked
		% objects in each frame, and playing the video.

		% Create a video file reader.
		obj.reader = VideoReader(video_file);

		% Create two video players, one to display the video,
		% and one to display the foreground mask.
		obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
		obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);

		% Create System objects for foreground detection and blob analysis

		% The foreground detector is used to segment moving objects from
		% the background. It outputs a binary mask, where the pixel value
		% of 1 corresponds to the foreground and the value of 0 corresponds
		% to the background.

		obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
			'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);

		% Connected groups of foreground pixels are likely to correspond to moving
		% objects.  The blob analysis System object is used to find such groups
		% (called 'blobs' or 'connected components'), and compute their
		% characteristics, such as area, centroid, and the bounding box.

		obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
			'AreaOutputPort', true, 'CentroidOutputPort', true, ...
			'MinimumBlobArea', 400);
	end

	function tracks = initializeTracks()
		% create an empty array of tracks
		tracks = struct(...
			'id', {}, ...
			'bbox', {}, ...
			'kalmanFilter', {}, ...
			'age', {}, ...
			'totalVisibleCount', {}, ...
			'centroid', {}, ...
			'consecutiveInvisibleCount', {});
	end

	function frame = readFrame(ind)
		frame = read(obj.reader, ind);
	end

	function [centroids, bboxes, mask] = detectObjects(frame)

		% Detect foreground.
		mask = obj.detector.step(frame);

		% Apply morphological operations to remove noise and fill in holes.
		mask = imopen(mask, strel('rectangle', [3,3]));
		mask = imclose(mask, strel('rectangle', [15, 15]));
		mask = imfill(mask, 'holes');

		% Perform blob analysis to find connected components.
		[~, centroids, bboxes] = obj.blobAnalyser.step(mask);
	end

	function predictNewLocationsOfTracks()
		for i = 1:length(tracks)
			bbox = tracks(i).bbox;

			% Predict the current location of the track.
			predictedCentroid = predict(tracks(i).kalmanFilter);

			% Shift the bounding box so that its center is at
			% the predicted location.
			predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
			tracks(i).bbox = [predictedCentroid, bbox(3:4)];
			tracks(i).centroid = predictedCentroid;
		end
	end

	function [assignments, unassignedTracks, unassignedDetections] = detectionToTrackAssignment()

		nTracks = length(tracks);
		nDetections = size(centroids, 1);

		% Compute the cost of assigning each detection to each track.
		cost = zeros(nTracks, nDetections);
		for i = 1:nTracks
			cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
		end

		% Solve the assignment problem.
		costOfNonAssignment = 20;
		[assignments, unassignedTracks, unassignedDetections] = ...
			assignDetectionsToTracks(cost, costOfNonAssignment);
	end

	function updateAssignedTracks()
		numAssignedTracks = size(assignments, 1);
		for i = 1:numAssignedTracks
			trackIdx = assignments(i, 1);
			detectionIdx = assignments(i, 2);
			centroid = centroids(detectionIdx, :);
			bbox = bboxes(detectionIdx, :);

			% Correct the estimate of the object's location
			% using the new detection.
			correct(tracks(trackIdx).kalmanFilter, centroid);

			% Replace predicted bounding box with detected
			% bounding box.
			tracks(trackIdx).bbox = bbox;

			% update centroid info
			tracks(trackIdx).centroid = centroid;

			% Update track's age.
			tracks(trackIdx).age = tracks(trackIdx).age + 1;

			% Update visibility.
			tracks(trackIdx).totalVisibleCount = ...
				tracks(trackIdx).totalVisibleCount + 1;
			tracks(trackIdx).consecutiveInvisibleCount = 0;
		end
	end

	function updateUnassignedTracks()
		for i = 1:length(unassignedTracks)
			ind = unassignedTracks(i);
			tracks(ind).age = tracks(ind).age + 1;
			tracks(ind).consecutiveInvisibleCount = ...
				tracks(ind).consecutiveInvisibleCount + 1;
		end
	end

	function deleteLostTracks()
		if isempty(tracks)
			return;
		end

		invisibleForTooLong = 20;
		ageThreshold = 8;

		% Compute the fraction of the track's age for which it was visible.
		ages = [tracks(:).age];
		totalVisibleCounts = [tracks(:).totalVisibleCount];
		visibility = totalVisibleCounts ./ ages;

		% Find the indices of 'lost' tracks.
		lostInds = (ages < ageThreshold & visibility < 0.6) | ...
			[tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;

		% Delete lost tracks.
		tracks = tracks(~lostInds);
	end

	function createNewTracks()
		centroids = centroids(unassignedDetections, :);
		bboxes = bboxes(unassignedDetections, :);

		for i = 1:size(centroids, 1)

			centroid = centroids(i,:);
			bbox = bboxes(i, :);

			% Create a Kalman filter object.
			% kalmanFilter = configureKalmanFilter('ConstantAcceleration', ...
			% 	centroid, [200, 50], [100, 25], 100);
			params = k_params();
			kalmanFilter = configureKalmanFilter(params.motionModel, ...
				centroid, params.initialEstimateError, ...
				params.motionNoise, params.measurementNoise);

			% Create a new track.
			newTrack = struct(...
				'id', nextId, ...
				'bbox', bbox, ...
				'centroid', centroid, ...
				'kalmanFilter', kalmanFilter, ...
				'age', 1, ...
				'totalVisibleCount', 1, ...
				'consecutiveInvisibleCount', 0);

			% Add it to the array of tracks.
			tracks(end + 1) = newTrack;

			% Increment the next id.
			nextId = nextId + 1;
		end
	end

	function param = k_params
		param.motionModel           = 'ConstantAcceleration';
		param.initialLocation       = 'Same as first detection';
		param.initialEstimateError  = 1E5 * ones(1, 3);
		param.motionNoise           = [25, 10, 1];
		param.measurementNoise      = 25;
	end

	% function stripped_data = strip_output(verified_tracks)
	% 	stripped_data = strcat('{ids: ', mat2str(verified_tracks(:).id), ...
	% 		', bboxs: ', mat2str(verified_tracks(:).bbox), ...
	% 		', frame_number: ', int2str(frame_ind), ...
	% 		', centroids: ', mat2str(verified_tracks(:).centroid), '}');
	% 	% flog(verified_tracks(:).id)
	% 	% flog(verified_tracks(:).bbox)
	% 	% flog(frame_ind)
	% 	% flog(verified_tracks(:).centroid)
	% 	% stripped_data = struct(...
	% 	% 	'ids', verified_tracks(:).id, ...
	% 	% 	'bboxs', verified_tracks(:).bbox, ...
	% 	% 	'frame_number', frame_ind, ...
	% 	% 	'centroids', verified_tracks(:).centroid);
	% end

	function displayTrackingResults()
		% Convert the frame and the mask to uint8 RGB.
		frame = im2uint8(frame);
		mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

		minVisibleCount = 8;
		if ~isempty(tracks)

			% Noisy detections tend to result in short-lived tracks.
			% Only display tracks that have been visible for more than
			% a minimum number of frames.
			reliableTrackInds = ...
				[tracks(:).totalVisibleCount] > minVisibleCount;
			reliableTracks = tracks(reliableTrackInds);

			% Display the objects. If an object has not been detected
			% in this frame, display its predicted bounding box.
			if ~isempty(reliableTracks)
				% Get bounding boxes.
				bboxes = cat(1, reliableTracks.bbox);

				% Get ids.
				ids = int32([reliableTracks(:).id]);

				% Create labels for objects indicating the ones for
				% which we display the predicted rather than the actual
				% location.
				labels = cellstr(int2str(ids'));
				predictedTrackInds = ...
					[reliableTracks(:).consecutiveInvisibleCount] > 0;
				isPredicted = cell(size(labels));
				isPredicted(predictedTrackInds) = {' predicted'};
				labels = strcat(labels, isPredicted);

				% Draw the objects on the frame.
				frame = insertObjectAnnotation(frame, 'rectangle', ...
					bboxes, labels);

				% Draw the objects on the mask.
				mask = insertObjectAnnotation(mask, 'rectangle', ...
					bboxes, labels);
			end

			confirmedTrackInds = ...
				[tracks(:).totalVisibleCount] > minVisibleCount & [tracks(:).consecutiveInvisibleCount] == 0;
			confirmedTracks = tracks(confirmedTrackInds);

			if ~isempty(confirmedTracks)
				flog(strcat('\nframe_number: ', int2str(frame_ind)));

				for i=1:numel(confirmedTracks)
					flog(strcat('\nid: ', YAML.dump([confirmedTracks(i).id])));
					flog(strcat('centroid: ', YAML.dump([confirmedTracks(i).centroid])));
					flog(strcat('bbox: ', YAML.dump([confirmedTracks(i).bbox])));
				end

				% flog(strcat('ids: ', YAML.dump([confirmedTracks(:).id])));
				% flog(strcat('centroids: ', YAML.dump([confirmedTracks(:).centroid])));
				% flog(strcat('bboxes: ', YAML.dump([confirmedTracks(:).bbox])));
				% disp('has confirmedTracks');
				% disp(size(confirmedTracks));
				% flog(YAML.dump(strip_output(confirmedTracks)));
				% flog(strip_output(confirmedTracks));
			end
		end

		% Display the mask and the frame.
		obj.maskPlayer.step(mask);
		obj.videoPlayer.step(frame);
	end

end

% % save data to yaml file
% car_data = struct('video_file_name', reader.Path, 'frames', reader.NumberOfFrames, 'framerate', reader.FrameRate);
% YAML.write('./car_data/video2_data.yaml', car_data)

% car_data_output = fopen('./car_data/video2_data.yaml', 'w')
% fprintf(car_data_output, YAML.dump(car_data));
% fclose(car_data_output);




% reader = VideoReader('./lens_corrected/GOPR0030.MP4');
% writer = VideoWriter('./lens_corrected/lens_corrected3.avi');

% numframes = reader.NumberOfFrames
% frame = read(reader, 100);

% % imshow(frame); -.32
% corrected = lensdistort(frame, -0.32, 'ftype', 3,  'bordertype', 'crop', 'interpolation', 'linear');

% figure;
%  imshow(corrected);

% hFig = figure('Toolbar','none',...
% 			'Menubar','none');
% hIm = imshow(corrected);
% hSP = imscrollpanel(hFig,hIm);
% api = iptgetapi(hSP);
% api.setMagnificationAndCenter(4,850,360)

% % uiwait(msgbox('Click the corners of the projection surface'));
% corners = zeros(4, 2);
% for ind = 1:4
% 	[x, y] = ginput(1);
% 	hold on;
% 	plot(x, y, 'r+', 'MarkerSize', 50);
% 	corners(ind, 1) = x;
% 	corners(ind, 2) = y;
% end

% side_len = 140;
% left_padding = 700;
% top_padding = 520;
% % target = [0 0; 0 1080; 1920 1080; 1920 0];
% target = [left_padding top_padding; left_padding top_padding+side_len; left_padding+side_len top_padding+side_len; left_padding+side_len top_padding];
% tform = estimateGeometricTransform(corners, target, 'projective');

% % outputview = imref2d([1080 1920]);
% outputview = imref2d([1080 1600]);
% % 1024 x 768
% warped = imwarp(corrected, tform, 'OutputView', outputview);
% figure, imshow(warped);

% uiwait(msgbox('Look good?'));

% open(writer);
% % for ind = 1:numframes-1
% for ind = 2000:20:2600
% 	disp(strcat('frame:', int2str(ind), '  of: ', int2str(numframes)));
% 	frame = read(reader, ind);
% 	corrected = lensdistort(frame, -0.32, 'ftype', 3,  'bordertype', 'crop', 'interpolation', 'linear');
%     warped = imwarp(corrected, tform, 'OutputView', outputview);
% 	writeVideo(writer, warped);
% end
% close(writer);