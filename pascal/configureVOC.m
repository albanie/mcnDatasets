function VOCopts = configureVOC(expDir, dataRoot, year) 
% CONFIGUREVOC configure VOC options to perform evaluation
%   CONFIGUREVOC(EXPDIR, DATAROOT, YEAR) configures the path options used 
%   in the Pascal VOC devkit to evaluate prediction against the VOC data
%   for the given YEAR stored in DATAROOT.  Intermediate prediction 
%   files are cached in a subfolder of the given EXPDIR. Regardless of the 
%   year of the data used for evaluation, the 2007 
%
%   NOTE: The Pascal VOC dataset has a number of directories 
%   and attributes. The paths to these directories are 
%   set using the VOCdevkit code. The VOCdevkit initialization 
%   code assumes it is being run from the devkit root folder, 
%   so we make a note of our current directory, change to the 
%   devkit root, initialize the pascal options and then change
%   back into our original directory 
%
% Copyright (C) 2017 Samuel Albanie 
% Licensed under The MIT License [see LICENSE.md for details]

  VOCRoot = fullfile(dataRoot, sprintf('VOCdevkit%d', year)) ;
  VOCopts.devkitCode = fullfile(VOCRoot, 'VOCcode') ;

  % check the existence of the required folders
  assert(logical(exist(VOCRoot, 'dir')), 'VOC root directory not found') ;
  assert(logical(exist(VOCopts.devkitCode, 'dir')), 'devkit code not found') ;
  currentDir = pwd ; cd(VOCRoot) ; addpath(VOCopts.devkitCode) ;
  VOCinit ; % VOCinit loads database options into a variable called VOCopts

  dataDir = fullfile(VOCRoot, num2str(year)) ;
  VOCopts.localdir = fullfile(dataDir, 'local') ;
  VOCopts.imgsetpath = fullfile(dataDir, 'ImageSets/Main/%s.txt') ;
  VOCopts.imgpath = fullfile(dataDir, 'ImageSets/Main/%s.txt') ;
  VOCopts.annopath = fullfile(dataDir, 'Annotations/%s.xml') ;
  VOCopts.cacheDir = fullfile(expDir, num2str(year), 'Results/Cache') ;
  VOCopts.drawAPCurve = false ;
  detDir = fullfile(expDir, 'VOCdetections') ;

  % create detection and cache directories if required
  requiredDirs = {VOCopts.localdir, VOCopts.cacheDir, detDir} ;
  for i = 1:numel(requiredDirs)
      reqDir = requiredDirs{i} ;
      if ~exist(reqDir, 'dir') , mkdir(reqDir) ; end
  end
  VOCopts.detrespath = fullfile(detDir, sprintf('%%s_det_%s_%%s.txt', 'test')) ;
  cd(currentDir) ; % return to original directory
