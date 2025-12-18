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
volumeViewer(data)

%% This is an image with zeros in the background and ones in the sample region
mask = data;
mask(mask>0.001) = 1;
mask = uint8(mask);

%% THRESHOLD
threshold_low= 0.5405; % 0.5405;

%% MASKS

%binarise
bin = data;
bin(bin<threshold_low) = 0;
bin(bin>threshold_low) = 1;

% change format to uint8, which makes some things easier later on
bin = uint8(bin);

%pores_temp = ~bin;
%pores_cleared = imclearborder(pores_temp);
%bin_1 = ~pores_cleared;

%% 3D view of bin
% extract and plot slices through volume
slice1(:,:) = bin(50,:,:);
slice2(:,:) = bin(:,100,:);
slice3(:,:) = bin(:,:,200);

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

%% WATERSHED METHOD

% get rid of isolated points in binary
bin2 = bwareaopen(bin,4500); % filters out shapes with less than 4500 px away from the binary

% Calculate the distance map for the watershed transform
D1 = bwdist(bin2); % creates a topographic map where farther away px from boudnaries get higher values (peak)
% multiple the image by the “mask” to get rid of regions outside the sample
D1 = D1.*single(mask); % force values outside the ROI to become zero

% filter out local maxima
D2 = imhmax(D1,5); % supresses shallow peaks in the distance map
L = watershed(-D2); % watershed finds the minima. by - the D2 we turn peaks into valleys allowing the watershed to fill them up and find the boundaries
labels = L .* uint16(mask); % converts the output L and mask into integers. any px where mask is 0 becomes 0

%%
% count number of pixels in each label (volume):
stats = regionprops3(labels, 'SurfaceArea','Volume', 'PrincipalAxisLength'); % take labelled map and calculate physical statistics for every object
volume = cat(1, stats.Volume);
surfaceArea = cat(1, stats.SurfaceArea);

L1 = stats.PrincipalAxisLength(:,1); % Longest
L2 = stats.PrincipalAxisLength(:,2); % Middle
L3 = stats.PrincipalAxisLength(:,3); % Shortest
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


% 1. Calculate Sphericity using the formula
% (Make sure volume and surfaceArea are from your regionprops3 step)
sphericity = (pi^(1/3) * (6 * volume).^(2/3)) ./ surfaceArea;

% 2. Plot the results
figure(8)
histogram(sphericity, 50)
title('Sphericity Distribution')
xlabel('Sphericity (1.0 = Perfect Sphere)')
ylabel('Number of Bubbles')
xlim([0 1.1]) % Sphericity is always between 0 and 1
grid on

%%

% Calculate Flatness Ratio (Thickness / Width)
% Small number = Flake. Large number (near 1) = Compact.
flatness = L3 ./ L2;

% Calculate Elongation Ratio (Width / Length)
% We usually don't care about this for flakes, but it helps filter needles.
elongation = L2 ./ L1;

% Define your cutoff (Adjust this after viewing results)
flatness_cutoff = 0.6; 

% Create logical filters
is_lamellar = flatness < flatness_cutoff;  % Thin (Flakes)
is_compact  = flatness >= flatness_cutoff; % Chunky (Compacted)

% Separate the tables
flakes = stats(is_lamellar, :);
compacted = stats(is_compact, :);

% Print the counts
fprintf('Found %d Flakes and %d Compacted Particles.\n', height(flakes), height(compacted));

% Plot Flatness vs Elongation (Zingg Plot)
figure;
scatter(elongation, flatness, 15, 'filled');
hold on
yline(flatness_cutoff, 'r--', 'LineWidth', 2); % Draw the cutoff line
xlabel('Elongation (Width / Length)');
ylabel('Flatness (Thickness / Width)');
title('Particle Shape Classification');
legend('Particles', 'Cutoff Line');
grid on;
text(0.5, 0.45, 'FLAKES (Lamellar)', 'Color', 'red', 'FontSize', 12)
text(0.4, 0.8, 'COMPACTED', 'Color', 'blue', 'FontSize', 12)

%%

volumeViewer(labels)