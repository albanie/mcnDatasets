function imdb = getFerImdb(dataDir)
%GETFERIMDB Returns imdb (the image database)
%  IMDB = GETFERIMDB(DATADIR) loads the FER image datbase.  This functions
%  assumes that the raw data `fer2013.csv` has been downloaded and placed
%  in DATADIR.
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  rawFaceDims = [48 48 1] ;
  dataPath = fullfile(dataDir, 'fer2013.csv') ;

  if ~exist(dataPath, 'file')
    fetchDataset('fer2013', dataPath) ;
  end
  csvData = importdata(dataPath) ;

  % parse data
  csvData = csvData(2:end) ; % skip header
  numRows = numel(csvData) ; % skip header
  labels = zeros(1, numRows) ;
  subset = zeros(1, numRows) ;
  imData = zeros(48, 48, 1, numRows, 'single') ;
  parfor ii = 1:numRows
    fprintf('extracting example %d/%d\n', ii, numRows) ;
    tokens = strsplit(csvData{ii}, ',') ;
    labels(ii) = str2double(tokens{1}) + 1 ; % labels need to be one-indexed
    switch tokens{3}
      case 'Training', setIdx = 1 ;
      case 'PublicTest', setIdx = 2 ;
      case 'PrivateTest', setIdx = 3 ;
      otherwise, error('%s not recognised', tokens{3}) ;
    end
    subset(ii) = setIdx ;
    pixels = single(cellfun(@str2double, strsplit(tokens{2}, ' '))) ;
    face = reshape(pixels, rawFaceDims)' ;
    imData(:,:,:,ii) = face ;
  end

  imdb.images.data = imData ;
  imdb.images.labels = labels ;
  imdb.images.set = subset ;
  imdb.meta.sets = {'train', 'val', 'test'} ;
  imdb.meta.classes = {'anger', 'disgust', 'fear', ...
                       'happiness', 'sadness', 'surprise', 'neutral'} ;

% -----------------------------------------
function fetchDataset(datasetName, dataPath)
% -----------------------------------------

  waiting = true ;
  prompt = sprintf(strcat('%s was not found at %s\nWould you like to ', ...
          ' download it from THE INTERNET (y/n)?\n'), datasetName, dataPath) ;

  while waiting
    str = input(prompt,'s') ;
    switch str
      case 'y'
        dataDir = fileparts(dataPath) ;
        if ~exist(dataDir, 'dir'), mkdir(dataDir) ; end
        fprintf(sprintf('Downloading %s ... \n', datasetName)) ;
        baseUrl = 'http://www.robots.ox.ac.uk/~albanie/data/mirrors' ;
        url = sprintf('%s/%s.tar', baseUrl, datasetName) ;
        % write the tar file to the same directory and unpack
        archivePath = fullfile(dataDir, sprintf('%s.tar', datasetName)) ;
        urlwrite(url, archivePath) ;
        % matlab builtin untar keeps breaking, so use cmd line
        cmd = sprintf('tar -xvf %s -C %s', archivePath, dataDir) ;
        status = system(cmd) ;
        if status > 0
          error(['automatic extraction failed, it will be necessary to '...
                                    'set up the dataset manually\n']) ;
        end
        % move data up a directory
        srcPath = fullfile(dataDir, 'fer2013/fer2013.csv') ;
        destPath = fullfile(dataDir, 'fer2013.csv') ;
        status = movefile(srcPath, destPath) ;
        if status ~= 1 % note that MATLAB uses 1 for a success :(
          error(['directory layout failed, it will be necessary to '...
                                    'set up the dataset manually\n']) ;
        end
        delete(archivePath) ; % clean up
        fprintf('successfully extracted the dataset!\n') ;
        return ;
      case 'n', throw(exception) ;
      otherwise, fprintf('input %s not recognised, please use `y/n`\n', str) ;
    end
  end
