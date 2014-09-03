% foveate.m
%
% Bill Overall
% Mar 12, 1999
%
% creates foveated image based on Gaussian multiresolution
% pyramid.  Uses formula from Geisler and Perry (1998) to
% determine spatial dropoff around a point of gaze.  Saves image
% as a full-quality jpg.
function outfile = foveate(infile, outfile)

use_ycbcr = 1; 				% use rgb or ycbcr for foveation?
levels = 7; 				% number of pyramid levels
fovx = 128; 				% x-pixel loc. of fovea center
fovy = 128; 				% y-pixel loc. of fovea center
CT0 = 1/75; 				% constant from Geisler&Perry
alpha = (0.106)*1; 			% constant from Geisler&Perry
epsilon2 = 2.3; 			% constant from Geisler&Perry
dotpitch = .225*(10^-3); 		% monitor dot pitch in meters
viewingdist = .445; 			% viewing distance in meters

% read file and store statistics from it
color_img = double(imread(infile))/255;

% normalize the values to some maximum value; for most MATLAB
% functions, this value must be one.
%max_cval = 1.0;
%range = [min(color_img(:)) max(color_img(:))];
img_size = size(color_img(:,:,1));
%color_img = max_cval.*(color_img-range(1)) ./ (range(2)-range(1));

% if we're using YCbCr values for foveation, then convert over to them now.
if use_ycbcr == 1
  color_img = rgb2ycbcr(color_img);
end

% ex and ey are the x- and y- offsets of each pixel compared to
% the point of focus (fovx,fovy) in pixels.
[ex, ey] = meshgrid(-fovx+1:img_size(2)-fovx,-fovy+1:img_size(1)-fovy);

% eradius is the radial distance between each point and the point
% of gaze.  This is in meters.
eradius = dotpitch .* sqrt(ex.^2+ey.^2);
clear ex ey;

% calculate ec, the eccentricity from the foveal center, for each
% point in the image.  ec is in degrees.
ec = 180*atan(eradius ./ viewingdist)/pi;

% maximum spatial frequency (cpd) which can be accurately represented onscreen:
maxfreq = pi ./ ((atan((eradius+dotpitch)./viewingdist) - ...
                  atan((eradius-dotpitch)./viewingdist)).*180);

clear eradius;
	      
% calculate the appropriate (fractional) level of the pyramid to use with
% each pixel in the foveated image.

% eyefreq is a matrix of the maximum spatial resolutions (in cpd)
% which can be resolved by the eye
eyefreq = ((epsilon2 ./(alpha*(ec+epsilon2))).*log(1/CT0));

% pyrlevel is the fractional level of the pyramid which must be
% used at each pixel in order to match the foveal resolution
% function defined above.
pyrlevel = maxfreq ./ eyefreq;

% constrain pyrlevel in order to conform to the levels of the
% pyramid which have been computed.
pyrlevel = max(1,min(levels,pyrlevel));

clear ec maxfreq;

% show the foveation region matrix: 

% create storage for our final foveated image
foveated = zeros(img_size(1),img_size(2),3);

% create matrices of x&y pixel values for use with interp3
[xi,yi] = meshgrid(1:img_size(2),1:img_size(1));

% we'll need to do the foveation procedure 3 times; once for each
% of the three color planes.
for color_idx = 1:3
  img = color_img(:,:,color_idx);
  
  % build Gaussian pyramid
  [pyr,indices] = buildGpyr(img,levels);

  % upsample each level of the pyramid in order to create a
  % foveated representation
  point = 1;
  blurtree = zeros(img_size(1),img_size(2),levels);
  for n=1:levels
    nextpoint = point + prod(indices(n,:)) - 1;
    show = reshape(pyr(point:nextpoint),indices(n,:));
    point = nextpoint + 1;
    blurtree(:,:,n) = ...
	imcrop(upBlur(show, n-1),[1 1 img_size(2)-1 img_size(1)-1]);
  end

  clear pyr indices;
  clear show;
  
  % create foveated image by interpolation
  foveated(:,:,color_idx) = interp3(blurtree,xi,yi,pyrlevel, '*linear');

end

clear color_img img;
clear xi yi;

% return to RGB representation if we converted to YCbCr
if use_ycbcr == 1
  foveated = ycbcr2rgb(foveated);
end


% readjust the range of the final image in order to ensure values
% 0.0 < foveated(i,j) < 1.0
%range = [min(foveated(:)) max(foveated(:))];
%foveated = (foveated-range(1)) ./ (range(2) - range(1));

imwrite(foveated,outfile);
