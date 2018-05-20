function imdb = getPascalYearImdb(dataDir, year, varargin)
% GETPASCALYEARIMDB - load Pascal IMDB file
%   IMDB = GETPASCALYEARIMDB(YEAR, OPTS) constructs an IMDB for the
%   Pascal VOC data associated with the given YEAR. This function wraps
%   the vocSetup code by Sebastien Erhardt and Andrea Vedaldi
%
%   GETPASCALYEARIMDB(..., 'option', value, ...) accepts the following
%   options:
%
%   `includeTest`:: false
%    Whether test images should be included into the imdb. Note that for the
%    2012 edition of the pascal VOC challenge, ground truth annotations for the
%    test set is stored on an evaluation server.  The images for 2012 test
%    partition must be downloaded manually.
%
%   `includeSegmentation`:: true
%    Include segmentation labels for the subset of labeled images.
%
%   `includeDevkit`:: false
%    Include development kit code released with the challenge.
%
%   `includeDetection`:: true
%    Include detection labels for the subset of labeled images.
%
%   `vocAdditionalSegmentations`:: false
%    Download and setup extra segmentation data from the Berkeley dataset. Note
%    that this is a large dataset, and downloading takes a long time.
%
%   `mergeMode`:: 2
%    The procedure for merging the Pascal and Berkely train/val sets.  See
%    vocSetupAdditionalSegmentations documentation for details on each mode.
%
% Copyright (C) 2017 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.mergeMode = 2 ;
  opts.includeTest = false ;
  opts.includeDevkit = false ;
  opts.includeDetection = true ;
  opts.includeSegmentation = true ;
  opts.vocAdditionalSegmentations = false ;
  opts = vl_argparse(opts, varargin) ;

  %dataDir = fullfile(opts.dataOpts.root, sprintf('pascal%d', year)) ;
  imdb = vocSetup('dataDir', dataDir, ...
    'edition', sprintf('%02d', year), ...
    'includeTest', opts.includeTest, ...
    'includeDevkit', opts.includeDevkit, ...
    'includeSegmentation', opts.includeSegmentation, ...
    'includeDetection', opts.includeDetection) ;

  if opts.vocAdditionalSegmentations
    imdb = vocSetupAdditionalSegmentations(imdb, 'dataDir', dataDir, ...
                                                  'dataDir', dataDir, ...
                                               'mergeMode', opts.mergeMode) ;
  end
