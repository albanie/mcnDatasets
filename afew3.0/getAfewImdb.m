function imdb = getAfewImdb(opts, varargin)
%GETAFEWIMDB AFEW 3.0 imdb construction
%  IMDB = GETAFEWIMDB(OPTS) builds an image/video database for training and
%  testing on the AFEW 3.0 dataset
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.includeTest = false ;
  opts = vl_argparse(opts, varargin) ;

  imdb = afewSetup(opts) ;
  imdb.images.ext = 'jpg' ;

% ------------------------------
function imdb = afewSetup(opts)
% ------------------------------
  emotions = {'Angry', 'Disgust', 'Fear', 'Happy', ...
              'Sad', 'Surprise', 'Neutral'} ;
  faceDir = fullfile(opts.dataDir, 'Faces') ;
  subsets = {'Train', 'Val'} ;
  % determine track labels - note that the same video may be used (in different
  % segments) for both training and validation, so we need to collect labels
  % *per-subset*.
  labelMaps = {containers.Map, containers.Map} ;
  if opts.includeTest
    subsets{end+1} = 'Test' ; labelMaps{end+1} = containers.Map ;
  end
  for ii = 1:numel(subsets)
    fprintf('building label map for %s..\n', subsets{ii}) ;
    for jj = 1:numel(emotions)
      emo = emotions{jj} ;
      paths = zs_getSubdirs(fullfile(opts.dataDir, subsets{ii}, emo)) ;
      for kk = 1:numel(paths)
        [~,vidName,~] = fileparts(paths{kk}) ;
        msg = 'no track should be repeated in a single subset' ;
        assert(~any(ismember(labelMaps{ii}.keys(), vidName)), msg) ;
        labelMaps{ii}(vidName) = jj ; % use emotion index, rather than string
      end
    end
  end
  facePaths = zs_getImgsInSubdirs(faceDir, 'jpg') ;
  fprintf('found %d face images (expected 100048) \n', numel(facePaths)) ;

  % to avoid issues with shared video names across subsets, generate a unique
  % index per track
  numTracks = sum(cellfun(@(x) numel(x.keys()), labelMaps)) ;

  % use FER2013 ordering
  relPaths = cell(1, numTracks) ;
  subsetIdx = zeros(1, numTracks) ;
  labels = zeros(1, numTracks) ;

  counter = 1 ;
  sortedVidNames = cellfun(@(x) sort(x.keys()), labelMaps, 'uni', 0) ;
  for ii = 1:numel(subsets)
    subset = subsets{ii} ;
    sortedVids = sortedVidNames{ii} ;
    for jj = 1:numel(sortedVids)
      fprintf('processing %d/%d (%s)\n', jj, numel(sortedVids), subset) ;
      vidName = sortedVids{jj} ;
      faceDir = fullfile(opts.dataDir, 'Faces', subset, vidName) ;
      paths = zs_getImgsInSubdirs(faceDir, 'jpg') ;
      tails = cellfun(@(x) getTail(x, 2), paths, 'Uni', 0) ;
      relPaths{counter} = tails ;
      subsetIdx(counter) = ii ;
      labels(counter) = labelMaps{ii}(vidName) ;
      counter = counter + 1 ;
    end
  end

  assert(counter - 1 == 383 + 773, 'unexpected number of tracks') ;

  imdb.tracks.paths = relPaths ;
  imdb.tracks.labels = labels ;
  imdb.tracks.labelsFerPlus = convertFerToFerPlus(labels, emotions) ;
  imdb.images.set = subsetIdx ;
  imdb.meta.classes = emotions ;
  imdb.meta.sets = subsets ;

  % check statistics against expected numbers
  msg = 'emotion statistics do not match expected numbers' ;
  assert(sum(imdb.images.set == 1 & imdb.images.labels == 1) == 133, msg) ;

% -------------------------------------------------------------------------
function labels = convertFerToFerPlus(labels, ferEmotions)
% -------------------------------------------------------------------------
% convert FER labels to FERplus emotion indices
  ferPlusEmotions = {'neutral', 'happiness', 'surprise', 'sadness', ...
                  'anger', 'disgust', 'fear', 'contempt'} ;
  % match strings
  strMap = containers.Map() ;
  strMap('Happy') = 'happiness' ;
  strMap('Sad') = 'sadness' ;
  strMap('Neutral') = 'neutral' ;
  strMap('Surprise') = 'surprise' ;
  strMap('Disgust') = 'disgust' ;
  strMap('Fear') = 'fear' ;
  strMap('Angry') = 'anger' ;

  % generate label permutation array
  permuteMap = cellfun(@(x) find(strcmp(strMap(x), ferPlusEmotions)), ...
                        ferEmotions) ;
  msg = 'contempt should not exist in original labels' ;
  assert(~ismember(8, permuteMap), msg) ;
  labels_ = permuteMap(labels) ;

% ---------------------------------------
function tail = getTail(path, numTokens)
% ---------------------------------------
  tokens = strsplit(path, '/') ;
  tail = fullfile(tokens{end-numTokens+1:end}) ;