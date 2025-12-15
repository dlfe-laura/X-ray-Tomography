clear
close all

imstart =0;
imend=399;

for i = imstart:imend
    data(:,:, i-imstart+1) = im2double(imread( ...
        strcat('C:\Users\la3314de\Downloads\foam2_40kV_3micron_16bit/foam2_40kV_3micron', num2str(i,'%04d'), '.tif')));
end

% extract and plot slices through volume
slice1(:,:) = data(50,:,:);
slice2(:,:) = data(:,100,:);
slice3(:,:) = data(:,:,200);

figure(1)
subplot(1,3,1)
pcolor(slice1')
shading flat
daspect([1 1 1])
subplot(1,3,2)
pcolor(slice2')
shading flat
daspect([1 1 1])
subplot(1,3,3)
pcolor(slice3')
shading flat
daspect([1 1 1])

% change colormap (if you want to!)
colormap(hot)

%%

% make histogram of grey-scale values to see different intensities

% plot histogram
figure(2)
histogram(data,1000)

% define yscale as logarithmic to see
%smaller peaks in histogram
set(gca,'YScale','log')

%% This is an image with zeros in the background and ones in the sample region

mask = data;
mask(mask>0.001) = 1;
mask = uint8(mask);

%%

% extract and plot slices through volume
slice1(:,:) = mask(50,:,:);
slice2(:,:) = mask(:,100,:);
slice3(:,:) = mask(:,:,200);

figure(3)
subplot(1,3,1)
pcolor(slice1')
shading flat
daspect([1 1 1])
subplot(1,3,2)
pcolor(slice2')
shading flat
daspect([1 1 1])
subplot(1,3,3)
pcolor(slice3')
shading flat
daspect([1 1 1])

% change colormap (if you want to!)
colormap(hot)
%%

threshold = 0.1505; %lowest limit in imagej divided by max limit
%binarise
bin = data;
bin(bin<threshold) = 0;
bin(bin>threshold) = 1;


% change format to uint8, which makes some things easier later on
bin = uint8(bin);
%%

% extract and plot slices through volume
slice1(:,:) = bin(50,:,:);
slice2(:,:) = bin(:,100,:);
slice3(:,:) = bin(:,:,200);

figure(4)
subplot(1,3,1)
pcolor(slice1')
shading flat
daspect([1 1 1])
subplot(1,3,2)
pcolor(slice2')
shading flat
daspect([1 1 1])
subplot(1,3,3)
pcolor(slice3')
shading flat
daspect([1 1 1])

% change colormap (if you want to!)
colormap(hot)
%%

% get rid of isolated points in binary
bin2 = bwareaopen(bin,4500);

% Calculate the distance map for the watershed transform
D1 = bwdist(bin2);
% multiple the image by the “mask” to get rid of regions outside the sample
D1 = D1.*single(mask);

% filter out local maxima
D2 = imhmax(D1,5);
L = watershed(-D2);
% Fix for the .* error:
labels = uint32(L) .* uint32(mask);

%%

% count number of pixels in each label (volume):
stats = regionprops3(labels, 'SurfaceArea','Volume');
volume = cat(1, stats.Volume);
surfaceArea = cat(1, stats.SurfaceArea);

%%

% 1. Create a figure for Volume
figure(6)
histogram(volume, 50) % 50 bins is usually a good starting point
title('Distribution of Pore Volumes')
xlabel('Volume (pixels^3)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')

% 2. Create a figure for Surface Area
figure(7)
histogram(surfaceArea, 50)
title('Distribution of Pore Surface Areas')
xlabel('Surface Area (pixels^2)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')

%%
%sphericity

% 1. Calculate Sphericity using the formula
% (Make sure volume and surfaceArea are from your regionprops3 step)
sphericity = (pi^(1/3) * (6 * volume).^(2/3)) ./ surfaceArea;

% 2. Plot the results
figure(8)
histogram(sphericity, 50)
title('Bubble Sphericity Distribution')
xlabel('Sphericity (1.0 = Perfect Sphere)')
ylabel('Number of Bubbles')
xlim([0 1.1]) % Sphericity is always between 0 and 1
grid on

%%

volumeViewer(L)