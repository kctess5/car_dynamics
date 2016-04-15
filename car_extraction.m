close all;
% clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % load car data so we don't overwrite anything
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% car_data = YAML.read('./car_data/video2_data.yaml')

	% % read video from file
	reader = VideoReader('./lens_corrected/video2.avi');
	% numframes = reader.NumberOfFrames;
	test_frame = read(reader, 770);
	grey_test_frame = rgb2gray(test_frame);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % choose object to detect
%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% uiwait(msgbox('Click the corners of the object you would like to track. Use the overview window to move the zoom box wherever you want.'));
	% hFig = figure('Toolbar','none',...
	% 			'Menubar','none');
	% hIm = imshow(test_frame);

	% hSP = imscrollpanel(hFig,hIm);
	% set(hSP,'Units','normalized',...
	%         'Position',[0 .1 1 .9])

	% hMagBox = immagbox(hFig,hIm);
	% pos = get(hMagBox,'Position');
	% set(hMagBox,'Position',[0 0 pos(3) pos(4)]);
	% imoverview(hIm);

	% api = iptgetapi(hSP);
	% api.setMagnificationAndCenter(3,850,360)

	% corners = zeros(4, 2);
	% for ind = 1:4
	% 	[x, y] = ginput(1);
	% 	hold on;
	% 	plot(x, y, 'r+', 'MarkerSize', 50);
	% 	corners(ind, 1) = x;
	% 	corners(ind, 2) = y;
	% end

	% ROI = test_frame(int64(min(corners(:,2))):int64(max(corners(:,2))),int64(min(corners(:,1))):int64(max(corners(:,1))), :);
	% grey_ROI = rgb2gray(ROI);
	% figure, imshow(ROI);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply motion mask to find ROIs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scene_roi = grey_test_frame;%(200:500,600:1000);
figure, imshow(scene_roi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find SIFT/SURF feature points in the ROIs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	templatePoints =  detectSURFFeatures(grey_ROI);
	scenePoints =  detectSURFFeatures(scene_roi);

	% figure, imshow(grey_ROI), title('20 Strongest Feature Points from Box Image');
	% hold on;
	% strongest_tp = selectStrongest(templatePoints, 20);
	% plot(strongest_tp);

	% figure, imshow(scene_roi), title('200 Strongest Feature Points from Scene Image');
	% hold on;
	% strongest_sp = selectStrongest(scenePoints, 200);
	% plot(selectStrongest(scenePoints, 200));

%%%%%%%%%%%%%%%%%%
% extract features
%%%%%%%%%%%%%%%%%%

	[templateFeatures, templatePoints] = extractFeatures(grey_ROI, templatePoints, 'BlockSize', 11);
	[sceneFeatures, scenePoints] = extractFeatures(scene_roi, scenePoints, 'BlockSize', 11);

%%%%%%%%%%%%%%%%
% match features
%%%%%%%%%%%%%%%%

	templatePairs = matchFeatures(templateFeatures, sceneFeatures);
	matchedTemplatePoints = templatePoints(templatePairs(:, 1), :);
	matchedScenePoints = scenePoints(templatePairs(:, 2), :);

	figure;
	showMatchedFeatures(grey_ROI, scene_roi, matchedTemplatePoints, ...
	    matchedScenePoints, 'montage');
	title('Putatively Matched Points (Including Outliers)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find heading and position in pixel space
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [tform, inlierTemplatePoints, inlierScenePoints] = ...
%     estimateGeometricTransform(matchedTemplatePoints, matchedScenePoints, 'affine');
% figure;
% showMatchedFeatures(grey_ROI, scene_roi, inlierTemplatePoints, ...
%     inlierScenePoints, 'montage');
% title('Matched Points (Inliers Only)')





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