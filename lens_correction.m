close all;
% clear all;

% % load('./camera_calibration/params4.mat');

reader = VideoReader('./raw_video/GOPR0030.MP4');
writer = VideoWriter('./lens_corrected/lens_corrected3.avi');

numframes = reader.NumberOfFrames
frame = read(reader, 100);

% imshow(frame); -.32
corrected = lensdistort(frame, -0.32, 'ftype', 3,  'bordertype', 'crop', 'interpolation', 'linear');

figure;
 imshow(corrected);

hFig = figure('Toolbar','none',...
			'Menubar','none');
hIm = imshow(corrected);
hSP = imscrollpanel(hFig,hIm);
api = iptgetapi(hSP);
api.setMagnificationAndCenter(4,850,360)

% uiwait(msgbox('Click the corners of the projection surface'));
corners = zeros(4, 2);
for ind = 1:4
	[x, y] = ginput(1);
	hold on;
	plot(x, y, 'r+', 'MarkerSize', 50);
	corners(ind, 1) = x;
	corners(ind, 2) = y;
end

side_len = 140;
left_padding = 700;
top_padding = 520;
% target = [0 0; 0 1080; 1920 1080; 1920 0];
target = [left_padding top_padding; left_padding top_padding+side_len; left_padding+side_len top_padding+side_len; left_padding+side_len top_padding];
tform = estimateGeometricTransform(corners, target, 'projective');

% outputview = imref2d([1080 1920]);
outputview = imref2d([1080 1600]);
% 1024 x 768
warped = imwarp(corrected, tform, 'OutputView', outputview);
figure, imshow(warped);

uiwait(msgbox('Look good?'));

open(writer);
% for ind = 1:numframes-1
for ind = 2000:20:2600
	disp(strcat('frame:', int2str(ind), '  of: ', int2str(numframes)));
	frame = read(reader, ind);
	corrected = lensdistort(frame, -0.32, 'ftype', 3,  'bordertype', 'crop', 'interpolation', 'linear');
    warped = imwarp(corrected, tform, 'OutputView', outputview);
	writeVideo(writer, warped);
end
close(writer);