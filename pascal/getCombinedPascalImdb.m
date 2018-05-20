function imdb = getCombinedPascalImdb(opts, varargin)
% GETCOMBINEDPASCALIMDB - load Pascal IMDB file
%   IMDB = GETCOMBINEDPASCALIMDB(OPTS) constructs an IMDB for the
%   Pascal VOC data spanning the 2007 and 2012 dataset (commonly referred
%   to as the "0712" dataset in object detection.
%
%   GETCOMBINEDPASCALIMDBPASCALIMDB(..., 'option', value, ...) accepts
%   the following options:
%
%   `excludeDifficult`:: false
%    Remove objects labelled as "difficult" from the VOC training annotations.
%
%   `includeSegmentation`:: true
%    Include segmentation labels for the subset of labeled images.
%
%   `includeDevkit`:: true
%    Include development kit code released with the challenge.
%
%   `includeDetection`:: true
%    Include detection labels for the subset of labeled images.
%
%   Inspiration ancestry for code:
%      A.Vedaldi -> R.Girshick -> S.Albanie
%
% Copyright (C) 2017 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.includeDevkit = true ;
  opts.includeDetection = true ;
  opts.excludeDifficult = false ;
  opts.includeSegmentation = true ;
  opts.vocAdditionalSegmentations = true ;
  opts = vl_argparse(opts, varargin) ;

  % Although the 2012 data can be used during training, only
  % the 2007 test data is used for evaluation
  opts.VOCRoot = fullfile(opts.dataOpts.dataRoot, 'VOCdevkit2007' ) ;
  opts.devkitCode = fullfile(opts.VOCRoot, 'VOCcode') ;
  imdb = loadImdb(opts) ;
  opts.pascalOpts = loadPascalOpts(opts) ;

  % add meta information (inlcuding background class)
  imdb.meta.classes = [{'background'} opts.pascalOpts.classes'] ;
  classIds = 1:numel(imdb.meta.classes) ;
  imdb.classMap = containers.Map(imdb.meta.classes, classIds) ;
  imdb.images.ext = 'jpg' ;
  imdb.meta.sets = {'train', 'val', 'test'} ;

%-----------------------------------------
function pascalOpts = loadPascalOpts(opts)
%-----------------------------------------
% LOADPASCALOPTS Load the pascal VOC database options
%
% NOTE: The Pascal VOC dataset has a number of directories
% and attributes. The paths to these directories are
% set using the VOCdevkit code. The VOCdevkit initialization
% code assumes it is being run from the devkit root folder,
% so we make a note of our current directory, change to the
% devkit root, initialize the pascal options and then change
% back into our original directory

  % check the existence of the required folders
  assert(logical(exist(opts.VOCRoot, 'dir')), 'VOC root directory not found') ;
  assert(logical(exist(opts.devkitCode, 'dir')), 'devkit code not found') ;
  currentDir = pwd ; cd(opts.VOCRoot) ; addpath(opts.devkitCode) ;
  VOCinit ; % VOCinit loads database options into a variable called VOCopts
  pascalOpts = VOCopts ; cd(currentDir) ;

%-----------------------------
function imdb = loadImdb(opts)
%-----------------------------
  dataDir07 = fullfile(opts.dataOpts.dataRoot, 'VOCdevkit2007', '2007') ;
  imdb07 = getPascalYearImdb(dataDir07, 07, ...
                         'includeDevkit', opts.includeDevkit, ...
                         'includeTest', true, ...
                         'includeDetection', opts.includeDetection, ...
                         'includeSegmentation', opts.includeSegmentation) ;
  dataDir12 = fullfile(opts.dataOpts.dataRoot, 'VOCdevkit2012', '2012') ;
  imdb12 = getPascalYearImdb(dataDir12, 12 , ...
         'includeTest', false, ... % download manually
         'includeDevkit', opts.includeDevkit, ...
         'includeDetection', opts.includeDetection, ...
         'includeSegmentation', opts.includeSegmentation, ...
         'vocAdditionalSegmentations', opts.vocAdditionalSegmentations) ;
  imdb = combineImdbs(imdb07, imdb12, opts) ;

% ------------------------------------------------
function imdb = combineImdbs(imdb07, imdb12, opts)
% ------------------------------------------------
  imdb.images.name = [imdb07.images.name, imdb12.images.name] ;
  imdb.images.set = [imdb07.images.set imdb12.images.set] ;
  imageSizes = [imdb07.images.size, imdb12.images.size] ;
  imdb.images.year = [ones(1,numel(imdb07.images.name)) * 2007 ...
                      ones(1,numel(imdb12.images.name)) * 2012] ;
  imdb.images.classification = [imdb07.images.classification ...
                                imdb12.images.classification] ;
  imdb.images.segmentation = [imdb07.images.segmentation ...
                                imdb12.images.segmentation] ;

  % add individual image paths for backward compatibility
  paths = vertcat(repmat(imdb07.paths.image, numel(imdb07.images.name), 1), ...
                   repmat(imdb12.paths.image, numel(imdb12.images.name), 1)) ;
  imdb.images.paths = arrayfun(@(x) {paths(x,:)}, 1:size(paths, 1)) ;

  % also include the paths from both years to handle optional extra segmentations
  imdb.paths2007 = imdb07.paths ;
  imdb.paths2012 = imdb12.paths ;

  % for consistency, store in Height-Width order
  imdb.images.imageSizes = arrayfun(@(x) {imageSizes([2 1],x)'}, ...
                                      1:size(imageSizes, 2)) ;
  if opts.includeDetection
    annot07 = loadAnnotations(imdb07, opts) ;
    annot12 = loadAnnotations(imdb12, opts) ;
    imdb.annotations = horzcat(annot07, annot12) ;
  end

% ------------------------------------------------
function annotations = loadAnnotations(imdb, opts)
% ------------------------------------------------
  annotations = cell(1, numel(imdb.images.name)) ;
  for ii = 1:numel(imdb.images.name)
    match = find(imdb.objects.image == ii) ;
    if opts.excludeDifficult
      keep = ~(imdb.objects.difficult(match)) ;
    else
      keep = 1:numel(match) ;
    end

    match = match(keep) ;
    boxes = imdb.objects.box(:,match) ;
    classes = imdb.objects.class(match) ;

    % normalize annotation
    imSize = repmat(imdb.images.size(:, ii)', [1 2]) ;
    gt.boxes = bsxfun(@rdivide, boxes', single(imSize)) ;
    gt.classes = classes + 1 ; % add offset for background
    assert(all(2 <= gt.classes) && all(gt.classes <= 21), ...
                 'pascal class labels do not lie in the expected range') ;
    annotations{ii} = gt ; fprintf('Loading annotaton %d \n', ii) ;
  end
