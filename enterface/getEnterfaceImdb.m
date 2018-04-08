function imdb = getEnterfaceImdb(opts, varargin)
%GETENTERFACE Enterface imdb construction
%  IMDB = GETENTERFACE(OPTS) builds an image/video database for training and
%  testing on the Enterface dataset
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.generateWavs = true ;
  opts = vl_argparse(opts, varargin) ;

  imdb = enterfaceSetup(opts) ;
  imdb.images.ext = 'jpg' ;
end

% ------------------------------
function imdb = enterfaceSetup(opts)
% ------------------------------
  emotions = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise'} ;
  % notation used in folders
  emoKeys = {'anger', 'disgust', 'fear', 'happiness', 'sadness', 'surprise'} ;
  faceDir = fullfile(opts.dataDir, 'faces') ;
  subsets = {'train', 'val'} ;
  trainIds = 1:30 ; valIds = 31:44 ;
  trainSpeakers = arrayfun(@(x) {sprintf('subject-%d', x)}, trainIds) ;
  valSpeakers = arrayfun(@(x) {sprintf('subject-%d', x)}, valIds) ;
  speakers = {trainSpeakers, valSpeakers} ;

  facePaths = zs_getImgsInSubdirs(faceDir, 'jpg') ;
  allTracks = cellfun(@fileparts, facePaths, 'uni', 0) ;
  numTracks = numel(unique(allTracks)) ;
  fprintf('found %d tracks (expected 1293) \n', numTracks) ;

  % use FER2013 ordering
  labels = zeros(1, numTracks) ;
  relPaths = cell(1, numTracks) ;
  vidNames = cell(1, numTracks) ;
  spIds = zeros(1, numTracks) ;
  subsetIdx = zeros(1, numTracks) ;
  vidPaths = cell(1, numTracks) ;
  if opts.generateWavs
    wavPaths = cell(1, numTracks) ;
  end

  % determine track labels
  counter = 1 ;
  for ii = 1:numel(subsets)
    subset = subsets{ii} ;
    subsetSpeakers = speakers{ii} ;
    for jj = 1:numel(subsetSpeakers)
      sp = subsetSpeakers{jj} ;
      emotionDirs = zs_getSubdirs(fullfile(faceDir, sp)) ;
      for kk = 1:numel(emotionDirs)
        sentenceDirs = zs_getSubdirs(emotionDirs{kk}) ;

        % The folder structure of the dataset is not consistent, so we
        % flatten sentence dirs that contain extra subfolders to ensure
        % an even depth
        if any(~ismember(sentenceDirs, allTracks))
          subdirs = cellfun(@zs_getSubdirs, sentenceDirs, 'uni', 0) ;
          sentenceDirs = [subdirs{:}] ; depth = 6 ;
        else
          depth = 5 ;
        end
        msg = 'incorrect track selection' ;
        assert(all(ismember(sentenceDirs, allTracks)), msg) ;

        for ll = 1:numel(sentenceDirs)
          fprintf('processing %d/%d (%s)\n', counter, numTracks, subset) ;
          [~,vidName,~] = fileparts(sentenceDirs{ll}) ;
          switch depth
            case 5
              [~,emoName] = fileparts(fileparts(sentenceDirs{ll})) ;
            case 6
              [~,emoName] = fileparts(fileparts(fileparts(sentenceDirs{ll}))) ;
            otherwise, error('unexpected folder depth %d\n', depth) ;
          end
          label = find(strcmp(emoKeys, emoName)) ;
          assert(numel(label) == 1, 'could not find appropriate label') ;
          paths = zs_getImgsInSubdirs(sentenceDirs{ll}, 'jpg') ;
          tails = cellfun(@(x) getTail(x, depth), paths, 'Uni', 0) ;
          relPaths{counter} = tails ;
          subsetIdx(counter) = ii ;
          labels(counter) = label ;
          vidNames{counter} = vidName ;

          % store path to video and generate wav if requested
          vidBasePath = strrep(sentenceDirs{ll}, 'faces', 'raw') ;
          vidPath = [vidBasePath '.avi'] ;
          assert(logical(exist(vidPath, 'file')), 'avi does not exist') ;
          vidPaths{counter} = vidPath ;
          if opts.generateWavs
            wavPaths{counter} = extractAudio(vidBasePath) ;
          end
          spIds(counter) = find(strcmp(sp, [speakers{:}])) ;
          counter = counter + 1 ;
        end
      end
    end
  end

  % sanity check expected track numbers
  assert(counter == 1294, 'unexpected number of tracks') ;

  imdb.tracks.vids = vidNames ;
  imdb.tracks.vidPaths = vidPaths ;
  imdb.tracks.paths = relPaths ;
  imdb.tracks.labels = labels ;
  imdb.tracks.labelsFerPlus = convertFerToFerPlus(labels, emotions) ;
  imdb.tracks.set = subsetIdx ;
  imdb.meta.classes = emotions ;
  imdb.meta.sets = subsets ;

  if opts.generateWavs
    imdb.tracks.wavPaths = wavPaths ;
  end

  % check statistics against expected numbers
  msg = 'emotion statistics do not match expected numbers' ;
  assert(sum(imdb.tracks.set == 1 & imdb.tracks.labels == 1) == 146, msg) ;
  imdb.tracks.id = 1:numTracks ;
end

% -------------------------------------------------------------------------
function destPath = extractAudio(vidBasePath)
% -------------------------------------------------------------------------
  srcPath = [vidBasePath '.avi'] ;
  destPath = [vidBasePath '.wav'] ;
  if ~exist(destPath, 'file')
    ffmpegBin = '/users/albanie/local/bin/ffmpeg' ;
    cmd = sprintf('%s -i %s -vn -acodec copy %s', ...
                              ffmpegBin, srcPath, destPath) ;
    status = system(cmd) ;
    if status ~= 0, keyboard ; end
  end
end

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
end

% ---------------------------------------
function tail = getTail(path, numTokens)
% ---------------------------------------
  tokens = strsplit(path, '/') ;
  tail = fullfile(tokens{end-numTokens+1:end}) ;
end
