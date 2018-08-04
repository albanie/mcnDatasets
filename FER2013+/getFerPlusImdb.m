function imdb = getFerPlusImdb(dataDir, varargin)
%GETFERPLUSIMDB Returns imdb (the image database)
%   IMDB = GETFERPLUSIMDB(DATADIR, VARARGIN) loads the FER+ image datbase.
%
%   GETFERPLUSIMDB(..'name', value) accepts the following options:
%
%   `dataType` :: 'CNTK'
%    This option which labels and images are included.
%    There are three options: "clean", which aggressively cleans the dataset,
%    "CNTK", which aims to follow the cleaning procedure described in the
%    Microsoft paper (link to the github page below), and "full", which does
%    not apply any form of cleaning.
%
%    Uses "plus" labels from: https://github.com/Microsoft/FERPlus
%    See the paper for more details: https://arxiv.org/abs/1608.01041
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.dataType = 'CNTK' ;
  opts = vl_argparse(opts, varargin) ;

  imdb = getFerImdb(dataDir) ;
  imdb = updateLabels(imdb, dataDir, opts.dataType) ;

% --------------------------------------------------------------------
function imdb = updateLabels(imdb, dataDir, dataType)
% --------------------------------------------------------------------

  plusLabelPath = fullfile(dataDir, 'fer2013new.csv') ;
  if ~exist(plusLabelPath, 'file')
    fetchDataset('fer2013+', plusLabelPath) ;
  end
  csvData = importdata(plusLabelPath) ;
  data = csvData.data ;
  header = csvData.textdata(1,:) ; emotions = header(3:10) ;
  subsets = csvData.textdata(2:end,1) ; % skip header

  switch dataType
    case 'clean'
      % use stronger labels to remove non-faces from the dataset (where the majority
      % of annotators agree that the image does not contain a face). We
      % also drop images where the majority vote by the annotators label is
      % "unknown".
      [~,cls] = max(data, [], 2) ;
      dropUnsure = sum(ismember(cls, 9)) ;
      dropNF = sum(ismember(cls, 10)) ;
      fprintf('dropped: %d non-face labels \n', dropNF) ;
      fprintf('dropped: %d unsure labels \n', dropUnsure) ;
      drop = find(ismember(cls, [9 10])) ;
      data(drop,:) = [] ;
      subsets(drop,:) = [] ;

      imdb.images.data(:,:,:,drop) = [] ;
      imdb.images.labels(drop) = [] ;
      imdb.images.set(drop) = [] ;
    case 'CNTK' % try to replicate the Microsoft cleaning process
      origData = data ;
      % remove emotions with a single vote (outlier removal)
      outliers = (data <= 1) ;
      data(outliers) = 0 ;
      dropped = 1 - sum(data(:))/sum(origData(:)) ;
      fprintf('dropped %.1f%% of votes as outliers\n', 100 * dropped) ;
      numVotes = sum(data, 2) ; % per row
      % following cntk processing - there are three reasons to drop examples:
      % (1) If the majority votes for either "unknown-face" or "not-face"
      % (2) If more than three votes share the maximum voting value
      % (3) If the max votes do not account for more than half of the votes
      toDrop = zeros(size(data,1), 1) ;
      for ii = 1:size(data,1)
        fprintf('processing %d/%d\n', ii, size(data,1)) ;
        maxVote = max(data(ii,:)) ;
        maxVoteEmos = find(data(ii,:) == maxVote) ;
        drop = any(ismember(maxVoteEmos, [9 10])) ; % reason (1)
        numMaxVotes = numel(maxVoteEmos) ;
        drop = drop || logical(numMaxVotes >= 3) ; % reason (2)
        drop = drop || logical((numMaxVotes * maxVote) <= 0.5 * numVotes(ii)) ; % reason (3)
        toDrop(ii) = drop ;
      end
      toDrop = logical(toDrop) ;
      data(toDrop,:) = [] ;
      subsets(toDrop,:) = [] ;
      imdb.images.data(:,:,:,toDrop) = [] ;
      imdb.images.labels(toDrop) = [] ;
      imdb.images.set(toDrop) = [] ;
    case 'full' % do nothing
    otherwise, error('unknown data type: %s\n', dataType) ;
  end
  imdb.images.oldLabels = imdb.images.labels ; % store FER original labels
  imdb.images = rmfield(imdb.images, 'labels') ; % remove to avoid confusion

  % use majority labels, and store votes
  [~,cls] = max(data, [], 2) ;
  imdb.images.votes = data ;
  imdb.images.hardLabels = cls' ;

  % sanity check the subset markers
  trainCorrect = all(ismember(subsets(imdb.images.set == 1), {'Training'})) ;
  valCorrect = all(ismember(subsets(imdb.images.set == 2), {'PublicTest'})) ;
  testCorrect = all(ismember(subsets(imdb.images.set == 3), {'PrivateTest'})) ;
  assert(trainCorrect, 'train subset does not match') ;
  assert(valCorrect, 'val subset does not match') ;
  assert(testCorrect, 'test subset does not match') ;

  imdb.meta.sets = {'train', 'val', 'test'} ;
  imdb.meta.classes = emotions ;

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
        url = sprintf('%s/%s.zip', baseUrl, datasetName) ;
        % write the tar file to the same directory and unpack
        archivePath = fullfile(dataDir, sprintf('%s.zip', datasetName)) ;
        urlwrite(url, archivePath) ;
        % matlab builtin untar keeps breaking, so use cmd line
        cmd = sprintf('unzip %s -d %s', archivePath, dataDir) ;
        status = system(cmd) ;
        if status > 0
          error(['automatic extraction failed, it will be necessary to '...
                                    'set up the dataset manually\n']) ;
        end
        % move data up a directory
        srcPath = fullfile(dataDir, 'fer2013+/fer2013new.csv') ;
        destPath = fullfile(dataDir, 'fer2013new.csv') ;
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
