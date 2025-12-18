clear
close all

%%
imstart =1;
imend=505;

for i = imstart:imend
    data(:,:, i-imstart+1) = im2double(imread( ...
        strcat('C:\Users\la3314de\Downloads\Group1\Group1\Group1_tomo-A_recon_Export_', num2str(i,'%04d'), '.tiff')));
end

%%

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


%% THRESHOLDS

threshold_high = 0.82;
threshold_low= 0.5405;

%% MASKS

mask_high = data > threshold_high;

mask_med = data > threshold_low & data <= threshold_high;

mask_low = data < threshold_low & (mask == 1);

% Uncomment which one is needed to be analyzed
bin = mask_high; % For bright pieces
%bin = mask_med; % For main material
%bin = mask_low; % For "pores"

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
bin2 = bwareaopen(bin,4500); % filters out shapes with less than 4500 px away from the binary

% Calculate the distance map for the watershed transform
D1 = bwdist(bin2); % creates a topographic map where farther away px from boudnaries get higher values (peak)
% multiple the image by the “mask” to get rid of regions outside the sample
D1 = D1.*single(mask); % force values outside the ROI to become zero

% filter out local maxima
D2 = imhmax(D1,5); % supresses shallow peaks in the distance map
L = watershed(-D2); % watershed finds the minima. by - the D2 we turn peaks into valleys allowing the watershed to fill them up and find the boundaries
% Fix for the .* error:
labels = uint16(L) .* uint16(mask); % converts the output L and mask into integers. any px where mask is 0 becomes 0

%%

% count number of pixels in each label (volume):
stats = regionprops3(labels, 'SurfaceArea','Volume');
volume = cat(1, stats.Volume);
surfaceArea = cat(1, stats.SurfaceArea);

%%

% Figure for volume
figure(6)
histogram(volume, 50) % 50 bins is usually a good starting point
title('Distribution of Pore Volumes')
xlabel('Volume (pixels^3)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')

% Figure for Surface Area
figure(7)
histogram(surfaceArea, 50)
title('Distribution of Pore Surface Areas')
xlabel('Surface Area (pixels^2)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')

%%

volumeViewer(labels)