close all;
% clear all;

% % load('./camera_calibration/params4.mat');

reader = VideoReader('./lens_corrected/video2.avi');
imshow(read(reader, 100));


wall = zeros(2, 2);
for ind = 1:2
	[x, y] = ginput(1);
	hold on;
	plot(x, y, 'r+', 'MarkerSize', 50);
	wall(ind, 1) = x;
	wall(ind, 2) = y;
end

wall_width = abs(wall(1:1) - wall(2:1))




% disp(reader.NumberOfFrames);
%videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
% numframes = reader.NumberOfFrames
% 
% for ind = 11697:5:11924
% 	disp(ind);
% 	% videoPlayer.step(read(reader, ind))
% 	imshow(read(reader, ind));
% 	pause(0.8)
% end

% frame = read(reader, 10347);
% imshow(frame);
% hold on;
% plot(647.8464518628527,456.65764835022924,'r.','MarkerSize',20)
% % frame = insertObjectAnnotation(frame, 'rectangle', ...
% % 					[805.0, 391.0, 84.0, 39.0]);