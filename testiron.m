close all
clear
clc

%% 1. CONFIGURATION
imstart = 1;
imend = 505;
threshold_low = 0.5405; 
basePath = 'C:\Users\la3314de\Downloads\Group1\Group1\Group1_tomo-A_recon_Export_';

%% 2. LOAD DATA
% Read first image to get dimensions
info = imfinfo([basePath, num2str(imstart,'%04d'), '.tiff']);
rows = info.Height;
cols = info.Width;
num_slices = imend - imstart + 1;

% Pre-allocate
data = zeros(rows, cols, num_slices, 'double');

fprintf('Loading %d slices...\n', num_slices);
for i = imstart:imend
    idx = i - imstart + 1;
    img = imread([basePath, num2str(i,'%04d'), '.tiff']);
    data(:,:,idx) = im2double(img);
end
fprintf('Data loaded.\n');

%% 3. FILTERING (Isolate Iron)
% Create a mask where Iron = 1, Pores = 0
iron_mask = data > threshold_low;

% OPTIONAL: Remove small floating noise (dust)
% iron_mask = bwareaopen(iron_mask, 50);

% Apply the mask to the original data
% This keeps the iron texture but forces everything else to absolute 0
iron_only_volume = data .* iron_mask;

%% 4. LAUNCH VOLUME VIEWER
% We pass the masked volume. The 'ScaleFactors' argument is optional
% but good if your pixels aren't perfect cubes (e.g. [1 1 1]).
fprintf('Launching Volume Viewer...\n');
volumeViewer(iron_only_volume);