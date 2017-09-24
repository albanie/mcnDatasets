function imdb = getPascalYearImdb(year, opts) 
% GETPASCALYEARIMDB - load Pascal IMDB file
%   IMDB = GETPASCALYEARIMDB(YEAR, OPTS) constructs an IMDB for the 
%   Pascal VOC data associated with the given YEAR. This function makes 
%   use of the vocSetup code by Sebastien Erhardt and Andrea Vedaldi
%
% Copyright (C) 2017 Samuel Albanie 
% Licensed under The MIT License [see LICENSE.md for details]

  dataDir = fullfile(opts.dataOpts.root, 'pascal%d', year) ;
  imdb = vocSetup('dataDir', dataDir, ...
    'edition', sprintf('%02d', year), ...
    'includeTest', opts.dataOpts.includeTest, ...
    'includeSegmentation', opts.dataOpts.includeSegmentation, ...
    'includeDetection', opts.dataOpts.includeDetection) ;

  if opts.dataOpts.vocAdditionalSegmentations
    imdb = vocSetupAdditionalSegmentations(imdb, 'dataDir', opts.dataDir) ;
  end
