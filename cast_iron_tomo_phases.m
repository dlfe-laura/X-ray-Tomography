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
% Create a layout grid: 1 row, 3 columns
t = tiledlayout(1,3); 
t.TileSpacing = 'compact';
t.Padding = 'compact';

% --- Slice 1 ---
nexttile
pcolor(slice1')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range (0=Black, 1=White)
title('XZ')

% --- Slice 2 ---
nexttile
pcolor(slice2')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range
title('YZ')

% --- Slice 3 ---
nexttile
pcolor(slice3')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range
title('XY')

% --- Shared Settings ---
colormap(hot)

% Add the shared colorbar to the layout (puts it on the right)
cb = colorbar;
cb.Layout.Tile = 'east'; 
cb.Label.String = 'Phase Presence (0=No, 1=Yes)';
%%
volumeViewer(data)

%%
% make histogram of grey-scale values to see different intensities

% plot histogram
figure(2)
histogram(data,1000)

% define yscale as logarithmic to see
%smaller peaks in histogram
set(gca,'YScale','log')
xlabel('Grey-scale value')
ylabel('Intensity (a.u)')

%% This is an image with zeros in the background and ones in the sample region

mask = data;
mask(mask>0.001) = 1;
mask = uint8(mask);

%% FIND THE REAL VALUES
% Pick a slice in the middle of your sample
mid_slice = data(:,:,100); 

% Open a tool to inspect pixel values
figure(99)
imshow(mid_slice, []) % Display with auto-scaling
title('HOVER over material to see values ->')
impixelinfo; % <--- This adds a tool at the bottom left
%% THRESHOLDS

threshold_high = 0.82;
threshold_low= 0.5055; % 0.5405;

%% MASKS

mask_high = data > threshold_high;

mask_med = data > threshold_low & data <= threshold_high;

mask_low = data < threshold_low & (mask == 1);

mask_study = data > 0.5055;

% Uncomment which one is needed to be analyzed
%bin = mask_high; % For bright pieces
bin = mask_med; % For main material
%bin = mask_low; % For "pores"
%bin = mask_study;

% change format to uint8, which makes some things easier later on
bin = uint8(bin);

%% 3D view of bin
CC = bwconncomp(bin);
L = labelmatrix(CC);
volumeViewer(L)
%%

% extract and plot slices through volume
slice1(:,:) = bin(50,:,:);
slice2(:,:) = bin(:,100,:);
slice3(:,:) = bin(:,:,200);

figure(4)
% Create a layout grid: 1 row, 3 columns
t = tiledlayout(1,3); 
t.TileSpacing = 'compact';
t.Padding = 'compact';

% --- Slice 1 ---
nexttile
pcolor(slice1')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range (0=Black, 1=White)
title('XZ')

% --- Slice 2 ---
nexttile
pcolor(slice2')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range
title('YZ')

% --- Slice 3 ---
nexttile
pcolor(slice3')
shading flat
daspect([1 1 1])
clim([0 1]) % Locks color range
title('XY')

% --- Shared Settings ---
colormap(hot)

% Add the shared colorbar to the layout (puts it on the right)
cb = colorbar;
cb.Layout.Tile = 'east'; 
cb.Label.String = 'Phase Presence (0=No, 1=Yes)';
