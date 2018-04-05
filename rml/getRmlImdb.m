function imdb = getRmlImdb(opts, varargin)
%GETRMLIMDB Rml imdb construction
%  IMDB = GETRMLIMDB(OPTS) builds an image/video database for training and
%  testing on the RML dataset
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  imdb = rmlSetup(opts) ;
  imdb.images.ext = 'jpg' ;

% ------------------------------
function imdb = rmlSetup(opts)
% ------------------------------
  emotions = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise'} ;
  emoKeys = {'an', 'di', 'fe', 'ha', 'sa', 'su'} ; % notation used in folders
  faceDir = fullfile(opts.dataDir, 'faces') ;
  subsets = {'rml-1', 'rml-2'} ;
  speakers = {{'s1', 's2', 's3', 's4', 's5'}, {'s6', 's7', 's8'}} ;

  facePaths = zs_getImgsInSubdirs(faceDir, 'jpg') ;
  allTracks = cellfun(@fileparts, facePaths, 'uni', 0) ;
  numTracks = numel(unique(allTracks)) ;
  fprintf('found %d tracks (expected 720) \n', numTracks) ;

  % use FER2013 ordering
  labels = zeros(1, numTracks) ;
  relPaths = cell(1, numTracks) ;
  vidNames = cell(1, numTracks) ;
  spIds = zeros(1, numTracks) ;
  subsetIdx = zeros(1, numTracks) ;

  % determine track labels
  counter = 1 ;
  for ii = 1:numel(subsets)
    subset = subsets{ii} ;
    subsetSpeakers = speakers{ii} ;
    for jj = 1:numel(subsetSpeakers)
      sp = subsetSpeakers{jj} ;
      tracks = zs_getSubdirs(fullfile(faceDir, subset, sp)) ;
      % flatten speakers with multiple languages
      if any(~ismember(tracks, allTracks))
        subTracks = cellfun(@zs_getSubdirs, tracks, 'uni', 0) ;
        tracks = [subTracks{:}] ; depth = 6 ;
      else
        depth = 5 ;
      end
      assert(all(ismember(tracks, allTracks)), 'incorrect track selection') ;

      for kk = 1:numel(tracks)
        fprintf('processing %d/%d (%s)\n', counter, numTracks, subset) ;
        [~,vidName,~] = fileparts(tracks{kk}) ;
        label = find(strcmp(emoKeys, vidName(1:2))) ;
        assert(numel(label) == 1, 'could not find appropriate label') ;
        paths = zs_getImgsInSubdirs(tracks{kk}, 'jpg') ;
        tails = cellfun(@(x) getTail(x, depth), paths, 'Uni', 0) ;
        relPaths{counter} = tails ;
        subsetIdx(counter) = ii ;
        labels(counter) = label ;
        vidNames{counter} = vidName ;
        spIds(counter) = find(strcmp(sp, [speakers{:}])) ;
        counter = counter + 1 ;
      end
    end
  end

  % sanity check expected track numbers
  assert(counter == 721, 'unexpected number of tracks') ;

  imdb.tracks.vids = vidNames ;
  imdb.tracks.paths = relPaths ;
  imdb.tracks.labels = labels ;
  imdb.tracks.labelsFerPlus = convertFerToFerPlus(labels, emotions) ;
  imdb.tracks.set = subsetIdx ;
  imdb.meta.classes = emotions ;
  imdb.meta.sets = subsets ;

  % check statistics against expected numbers
  msg = 'emotion statistics do not match expected numbers' ;
  assert(sum(imdb.tracks.set == 1 & imdb.tracks.labels == 1) == 66, msg) ;
  imdb.tracks.id = 1:numTracks ;

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
  labels = permuteMap(labels) ;

% ---------------------------------------
function tail = getTail(path, numTokens)
% ---------------------------------------
  tokens = strsplit(path, '/') ;
  tail = fullfile(tokens{end-numTokens+1:end}) ;
