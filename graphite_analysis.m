clear
close all

%% IMPORT MY DATA
imstart =1;
imend=505;

for i = imstart:imend
    data(:,:, i-imstart+1) = im2double(imread( ...
        strcat('C:\Users\la3314de\Downloads\Group1\Group1\Group1_tomo-A_recon_Export_', num2str(i,'%04d'), '.tiff')));
end

%% MASK (This is an image with zeros in the background and ones in the sample region)
mask = data;
mask(mask>0.001) = 1;
mask = uint8(mask);

%% THRESHOLD
threshold_low= 0.5405; 

%% BINARIZATION
bin = data;
bin(bin<threshold_low) = 0;
bin(bin>threshold_low) = 1;

% change format to uint8, which makes some things easier later on
bin = uint8(bin);

%% CHECK BINARIZATION
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
bin2 = bwareaopen(bin,4500); % Removes small, isolated islands of rion

% Calculate the distance map for the watershed transform
D1 = bwdist(bin2); % creates a topographic map where farther away px from boudnaries get higher values (graphite peak)
% multiple the image by the “mask” to get rid of regions outside the sample
D1 = D1.*single(mask); % force values outside the cylinder to become zero

% filter out local maxima
D2 = imhmax(D1,5); % supresses shallow peaks in the distance map
L = watershed(-D2); % watershed finds the minima. by - the D2 we turn peaks into valleys allowing the watershed to fill them up and find the boundaries
labels = L .* uint16(mask); % converts the output L and mask into integers. any px where mask is 0 becomes 0

%% CHARACTERIZATION
% count number of pixels in each label (volume):
stats = regionprops3(labels, 'SurfaceArea','Volume', 'PrincipalAxisLength'); % take labelled map and calculate physical statistics for every object

volume = cat(1, stats.Volume);

surfaceArea = cat(1, stats.SurfaceArea);

L1 = stats.PrincipalAxisLength(:,1); % Longest
L2 = stats.PrincipalAxisLength(:,2); % Middle
L3 = stats.PrincipalAxisLength(:,3); % Shortest
%% CHARACTERIZATION FIGURES (Volume, Surface Area, Sphericity)

% Volume
figure(6)
histogram(volume, 100) 
%title('Distribution of Graphite Spheroids Volume')
xlabel('Volume (px^3)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')
%exportgraphics(figure(6), 'volume_distribution.png', 'Resolution', 300);

% Surface Area
figure(7)
histogram(surfaceArea, 100)
%title('Distribution of Graphite Spheroid Surface Area')
xlabel('Surface Area (px^2)')
ylabel('Frequency')
grid on
set(gca, 'YScale', 'log')
%exportgraphics(figure(7), 'surface_distribution.png', 'Resolution', 300);


% Sphericity 
sphericity = (pi^(1/3) * (6 * volume).^(2/3)) ./ surfaceArea;
figure(8)
histogram(sphericity, 100)
%title('Sphericity Distribution')
xlabel('Sphericity (1.0 = Perfect Sphere)')
ylabel('Number of Spheroids')
xlim([0 1.1]) % Sphericity is always between 0 and 1
grid on
%exportgraphics(figure(8), 'sphericity.png', 'Resolution', 300);

%% SHAPE

% Calculate Flatness Ratio (Thickness / Width)
% Small number = Flake. Large number (near 1) = Compact.
flatness = L3 ./ L2;

% Calculate Elongation Ratio (Width / Length)
% We usually don't care about this for flakes, but it helps filter needles.
elongation = L2 ./ L1;

% Define the cutoff
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
figure(9);
scatter(elongation, flatness, 15, 'filled');
hold on
yline(flatness_cutoff, 'r--', 'LineWidth', 2); % Draw the cutoff line
xlabel('Elongation Ratio');
ylabel('Flatness Ratio');
%title('Particle Shape Classification');
legend('Particles', 'Cutoff Line');
lgd = legend;
lgd.Location = 'northwest';
grid on;
text(0.5, 0.45, 'FLAKES (Lamellar)', 'Color', 'red', 'FontSize', 12)
text(0.4, 0.8, 'COMPACTED', 'Color', 'blue', 'FontSize', 12)
%exportgraphics(figure(9), 'shape.png', 'Resolution', 300);


%% TOTAL VOLUME AND TOTAL SURFACE AREA

totalVolume = sum(stats.Volume);
totalSurfaceArea = sum(stats.SurfaceArea);

disp(['Total Volume: ', num2str(totalVolume)]);
% %f is a placeholder for a floating-point number
fprintf('Total Surface Area: %f\n', totalSurfaceArea);

%% NODULARITY

%Extract Volume and Surface Area as vectors
allVolumes = stats.Volume;
allSurfaceAreas = stats.SurfaceArea;

% Calculate Sphericity for every particle
% Formula: (Surface Area of equivalent sphere) / (Actual Surface Area)
% Numerator represents the surface area of a perfect sphere with volume V
numerator = (36 * pi * (allVolumes.^2)).^(1/3);
sphericity = numerator ./ allSurfaceAreas;

% Identify Nodules (Threshold > 0.6)
isNodule = sphericity >= 0.6;

% Calculate Volume Sums
% Sum of volume of ALL particles
sumVolAll = sum(allVolumes);
% Sum of volume of ONLY particles identified as nodules
sumVolNodules = sum(allVolumes(isNodule));

% Calculate Percent Nodularity
percentNodularity = (sumVolNodules / sumVolAll) * 100;

% --- Display Results ---
fprintf('Total Volume (All): %.2f\n', sumVolAll);
fprintf('Total Volume (Nodules): %.2f\n', sumVolNodules);
fprintf('Percent Nodularity: %.2f%%\n', percentNodularity);
