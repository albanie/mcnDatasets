function imdb = getSfewImdb(dataDir)
%GETSFEWIMDB Returns imdb (the image database)
%   IMDB = GETSFEWIMDB(DATADIR) loads the SFEW image datbase.  This
%   functions assumes that DATADIR is directory containing a collection
%   of images in png format arranged in three folders 'Train', 'Val'
%   and 'Test'.  'Train' and 'Val' are assumed to contain further subfolders,
%   each with the name of an emotion. 'Test' should contain an unlabelled
%   collection of png files (the labels for the test set are not publicly
%   available).
%
% Copyright (C) 2016 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

	trainIms = zs_getImgsInSubdirs(fullfile(dataDir, 'Train'), 'png') ;
	valIms = zs_getImgsInSubdirs(fullfile(dataDir, 'Val'), 'png') ;
	testIms = zs_getImgsInSubdirs(fullfile(dataDir, 'Test'), 'png') ;

	[trainData, trainLabels] = preprocessSFEW(trainIms, true) ;
	[valData, valLabels] = preprocessSFEW(valIms, true) ;
	testData = preprocessSFEW(testIms, false) ;

	trainSet = ones(1, size(trainData, 4)) ;
	valSet = 2 * ones(1, size(valData, 4)) ;
  testSet = 3 * ones(1, size(testData, 4)) ;

	imdb.images.data = cat(4, trainData, valData, testData) ;
	imdb.images.labels = cat(2, trainLabels, valLabels) ;
	imdb.images.set = [trainSet valSet testSet] ;
	imdb.meta.sets = {'train', 'val', 'test'} ;
	imdb.meta.classes = {'anger', 'disgust', 'fear', ...
			                 'happiness', 'sadness', 'surprise', 'neutral'} ;

% --------------------------------------------------------------------
function [data, labels] = preprocessSFEW(imList, extractLabels)
% --------------------------------------------------------------------
%PREPROCESSSFEW - preprocess images stored in the SFEW layout
%   [DATA, LABELS] = PREPROCESSSFEW(IMLIST, EXTRACTLABELS) loads the
%   the data from a cell array of paths to image files.  If EXTRACTLABELS
%   is set to TRUE, these image paths should each have the form:
%       SOME_DIR/EMOTION/IMG_NAME.PNG
%   The EMOTION subfolder will be used to produce a label for each image.
%   Alternatively, if EXTRACTLABELS is FALSE, the image paths should have the
%   form:
%       SOME_DIR/IMG_NAME.PNG
%
%   The function returns 96 x 96 x 3 x N data array containing the images. If
%   EXTRACTLABELS is TRUE, it will also return an Nx1 array of emotion labels.

	rawData = cellfun(@(x) {single(imread(x))}, imList) ;
	data = cat(4, rawData{:}) ;
  if extractLabels, labels = cellfun(@extractEmotion, imList)' ; end

% -----------------------------------------
function emotionLabel = extractEmotion(path)
% -----------------------------------------
	pathElems = strsplit(path, '/') ;
	emotionKey = pathElems{end - 1} ;
	keys = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral'} ;
	values = [1, 2, 3, 4, 5, 6. 7] ;
	emotionMap = containers.Map(keys, values) ;
	emotionLabel = emotionMap(emotionKey) ;
