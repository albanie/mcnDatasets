function setup_mcnDatasets()
%SETUP_MCNDATASETS Sets up mcnDatasets, by adding its folders
% to the Matlab path
%
% Copyright (C) 2017 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  root = fileparts(mfilename('fullpath')) ;
  addpath(root, [root '/pascal'], [root '/pascal/helpers'], [root '/coco']) ;
  addpath([root '/afew3.0'], [root '/rml']) ;
  addpath([root '/enterface'], [root '/sfew']) ;
  addpath([root '/FER2013'], [root '/FER2013+']) ;
