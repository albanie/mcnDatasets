function stats = getDatasetStatistics(imdb, varargin)
%GETDATASETSTATISTICS gather sementation statistics for VOC data
%  STATS = GETDATASETSTATISTICS(IMDB) collects mean and covariance 
%  statistics across the set of training images used in the Pascal
%  challenge
%
%   GETDATASETSTATISTICS(..., 'option', value, ...) accepts 
%   the following options:
%
%   `numClasses`:: 21
%    The number of classes of interest in the dataset 
%
% This script was sourced from the Matconvnet-fcn project, written by 
% Sebastien Erhardt and Andrea Vedaldi:
% https://github.com/vlfeat/matconvnet-fcnby Andrea Vedladi

  if isfield(imdb.images, 'segmentation')
    train = find(imdb.images.set == 1 & imdb.images.segmentation) ;
  else
    train = find(imdb.images.set == 1) ;
  end

  % Class statistics
  accumSz = [opts.numClasses 1] ;
  classCounts = zeros(accumSz) ;
  for ii = 1:numel(train)
    fprintf('%s: computing segs tats for training image %d\n', mfilename, ii) ;
    lb = imread(sprintf(imdb.paths.classSegmentation, imdb.images.name{train(ii)})) ;
    ok = lb < 255 ;
    classCounts = classCounts + accumarray(lb(ok(:))+1, 1, accumSz) ;
  end
  stats.classCounts = classCounts ;

  % Image statistics
  rgbm1 = cell(1, numel(train)) ;
  rgbm2 = cell(1, numel(train)) ;
  for t=1:numel(train)
    fprintf('%s: computing RGB stats for training image %d\n', mfilename, t) ;
    rgb = imread(sprintf(imdb.paths.image, imdb.images.name{train(t)})) ;
    rgb = single(rgb) ;
    z = reshape(permute(rgb,[3 1 2 4]),3,[]) ;
    n = size(z,2) ;
    rgbm1{t} = sum(z,2)/n ;
    rgbm2{t} = z*z'/n ;
  end

  rgbm1 = mean(cat(2,rgbm1{:}),2) ;
  rgbm2 = mean(cat(3,rgbm2{:}),3) ;
  stats.rgbMean = rgbm1 ;
  stats.rgbCovariance = rgbm2 - rgbm1*rgbm1' ;
