clear
close all

imstart =1;
imend=500;

for i = imstart:imend
    data(:,:, i-imstart+1) = im2double(imread( ...
        strcat('C:\Users\la3314de\Downloads\lego_tiffs_16bit/lego_tomo-recon', num2str(i,'%04d'), '.tif')));
end

% extract and plot slices through volume
slice1(:,:) = data(200,:,:);
slice2(:,:) = data(:,150,:);
slice3(:,:) = data(:,:,250);

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

%%

threshold = 0.686;
%binarise
bin = data;
bin(bin<threshold) = 0;
bin(bin>threshold) = 1;

%%

% extract and plot slices through volume for binarized data
slice1(:,:) = bin(100,:,:); % phase 1
slice2(:,:) = bin(:,150,:); % phase 2
slice3(:,:) = bin(:,:,250); % phase 3

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

CC = bwconncomp(bin);
L = labelmatrix(CC);
slice1(:,:) = L(100,:,:);
slice2(:,:) = L(:,150,:);
slice3(:,:) = L(:,:,250);

%%

% View the lego through the binarized slices that we selected in 3D
volumeViewer(L);

%%

% count number of pixels in each label (volume):
stats = regionprops3(L,'Volume');
volume = cat(1, stats.Volume);

histogram(volume);