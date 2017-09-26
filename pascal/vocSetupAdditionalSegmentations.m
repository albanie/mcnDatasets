function imdb = vocSetupAdditionalSegmentations(imdb, varargin)
%VOCSETUPADDITIONALSEGMENTATIONS Download additional Berkeley seg data for VOC 12
%   IMDB = VOCSETUPADDITIONALSEGMENTATIONS(IMDB) downloads and setups
%   Berkeley additional segmentations for the PASCAL VOC 2012 segmentation
%   challenge data.
%
%   Example::
%        imdb = vocSetup('dataDir', 'data/voc12') ;
%        imdb = vocSetupAdditionalSegmentations(...
%             imdb, 'dataDir', 'data/voc12') ;
%
%   There are several merge modes that can be selected using the
%   'mergeMode', option.
%
%   Let BT, BV, PT, PV, and PX be the Berkeley training and validation
%   sets and PASCAL segmentation challenge training, validation, and
%   test sets. Let T, V, X the final trainig, validation, and test
%   sets.
%
%   Mode 1::
%      V = PV (same validation set as PASCAL)
%
%   Mode 2:: (default))
%      V = PV \ BT (PASCAL val set that is not a Berkeley training
%      image)
%
%   Mode 3::
%      V = PV \ (BV + BT)
%
%   In all cases:
%
%      S = PT + PV + BT + BV
%      X = PX  (the test set is uncahgend)
%      T = (S \ V) \ X (the rest is training material)
%
% This script was sourced from the Matconvnet-fcn project, written by 
% Sebastien Erhardt and Andrea Vedaldi:
% https://github.com/vlfeat/matconvnet-fcn

  opts.dataDir = 'data/voc12' ;
  opts.archiveDir = 'data/archives' ;
  opts.mergeMode = 2 ;
  opts.url = ['http://www.eecs.berkeley.edu/Research/Projects/CS/vision/' ...
               'grouping/semantic_contours/benchmark.tgz'] ;
  opts = vl_argparse(opts, varargin) ;

  tempDir = fullfile(opts.dataDir, 'berkeley') ;
  haveData = exist(tempDir, 'dir') ;
  if haveData
    folder = fullfile(opts.dataDir, 'berkeley/benchmark_RELEASE/dataset/cls') ;
    files = dir(fullfile(folder, '*.mat')) ; haveData = ~isempty(files) ;
  end

  if ~haveData
    % Get Berkeley data - it is not gzipped so save without the gz extension
    % to avoid MATLAB choking
    archivePath = fullfile(opts.archiveDir, 'berkeleyVoc12Segments.tar') ; 
    if ~exist(archivePath, 'file')
      msg = '%s: downloading %s to %s [this may take a long time]\n' ;
      fprintf(msg, mfilename, opts.url, archivePath) ;
      websave(archivePath, opts.url) ;
    end
    mkdir(tempDir) ; untar(archivePath, tempDir) ; % Uncompress Berkeley data
  end

  mkdir(fullfile(opts.dataDir, 'SegmentationClassExt')) ;
  mkdir(fullfile(opts.dataDir, 'SegmentationObjectExt')) ;

  % Update training data
  base = fullfile(tempDir, 'benchmark_RELEASE', 'dataset') ;
  train = textread(fullfile(base, 'train.txt'), '%s','delimiter','\n') ; %#ok
  val = textread(fullfile(base, 'val.txt'), '%s','delimiter','\n') ; %#ok

  for i = 1:numel(imdb.images.id)
    name = imdb.images.name{i} ;
    isBT = any(find(strcmp(name, train))) ;
    isBV = any(find(strcmp(name, val))) ;

    isPT = imdb.images.segmentation(i) && imdb.images.set(i) == 1 ;
    isPV = imdb.images.segmentation(i) && imdb.images.set(i) == 2 ;
    isPX = imdb.images.segmentation(i) && imdb.images.set(i) == 3 ; % test

    % now decide how to use this image
    if ~(isBT || isBV || isPT || isPV || isPX)
      % not an image with segmentations
      continue ;
    end

    if isPX
      isX = true ;
      isT = false ;
      isV = false ;
    else
      switch opts.mergeMode
        case 1
          isV = isPV ;
        case 2
          isV = isPV & ~isBT ;
        case 3
          isV = isPV & ~isBT & ~isBV ;
      end
      isX = false ;
      isT = ~isV ;
    end

    % if this image is not in the berekeley data, copy it over
    % from the PASCAL DATA as is, otherwise use Berkely annotation
    for k = 1:2
      if k == 1
        dir1 = 'cls' ;
        dir2 = 'SegmentationClass' ;
        dir3 = 'SegmentationClassExt' ;
        f = 'GTcls' ;
      else
        dir1 = 'inst' ;
        dir2 = 'SegmentationObject' ;
        dir3 = 'SegmentationObjectExt' ;
        f = 'GTinst' ;
      end

      extPath = fullfile(tempDir, 'benchmark_RELEASE', 'dataset', dir1, [name '.mat']) ;
      pngPath = fullfile(opts.dataDir, dir2, [name '.png']) ;
      newPngPath = fullfile(opts.dataDir, dir3, [name '.png']) ;

      if ~exist(newPngPath, 'file')
        if imdb.images.segmentation(i)
          copyfile(pngPath, newPngPath, 'f') ;
        else
          anno = load(extPath) ;
          labels = anno.(f).Segmentation ;
          imwrite(uint8(labels),newPngPath) ;
        end
      end
    end
    imdb.images.segmentation(i) = true ;
    imdb.images.set(i) = isT + 2 * isV + 3 * isX ;
  end


  imdb.paths.classSegmentation = fullfile(opts.dataDir, 'SegmentationClassExt', '%s.png') ;
  imdb.paths.objectSegmentation = fullfile(opts.dataDir, 'SegmentationObjectExt', '%s.png') ;
