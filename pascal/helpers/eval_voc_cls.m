function res = eval_voc_cls(cls, image_ids, scores, VOCopts, varargin)
% RES = EVAL_VOC(CLS, IMAGE_IDS, SCORES, VOCOPTS)
%   Use the VOCdevkit to evaluate classifications specified in boxes
%   for class cls against the ground-truth boxes in the image
%   database IMDB. Results files are saved with an optional suffix.
%
% This is a modified version of Ross Girshick's Fast R-CNN code.

  % Add a random string ("salt") to the end of the results file name
  % to prevent concurrent evaluations from clobbering each other
  opts.use_res_salt = true ;
  opts.rm_res = true ; % Delete results files after computing APs
  opts.comp_id = 'comp2' ; % comp2 because we use outside data (ILSVRC2012)
  drawCurve = true ; % draw each class curve
  opts.suffix = '' ;
  opts.year = 2007 ;
  [opts, ~] = vl_argparse(opts, varargin) ;

  if ~strcmp(opts.suffix, ''), opts.suffix = ['_' opts.suffix] ; end
  if opts.use_res_salt
    prev_rng = rng ; rng shuffle ; salt = sprintf('%d', randi(100000)) ;
    res_id = [opts.comp_id '-' salt] ; rng(prev_rng) ;
  else 
    res_id = opts.comp_id ; 
  end

  % write out detections in PASCAL format and score
  res_fn = sprintf(VOCopts.clsrespath, res_id, cls);
  fid = fopen(res_fn, 'w') ;
  for i = 1:numel(image_ids)
    template = '%s %f\n' ;
    fprintf(fid, template, image_ids{i}, scores(i)) ;
  end
  fclose(fid) ;

  [recall, prec, ap] = VOCevalcls(VOCopts, res_id, cls, drawCurve) ;

  switch opts.year
    case 2007, ap_auc = VOCap07(recall, prec) ;
    case 2012, ap_auc = xVOCap(recall, prec) ;
    otherwise, error('Year %d not recognised', opts.year) ;
  end

  ylim([0 1]) ; xlim([0 1]) ; % force plot limits
  path = fullfile(VOCopts.cacheDir, sprintf('%s_pr_%s.jpg', cls, opts.suffix)) ;
  print(gcf, '-djpeg', '-r0', path) ; 
  fprintf('!!! %s : %.4f %.4f\n', cls, ap, ap_auc) ;
  path = fullfile(VOCopts.cacheDir,  sprintf('%s_pr_%s',cls, opts.suffix))  ;
  save(path, 'recall', 'prec', 'ap', 'ap_auc') ;
  res.recall = recall ; res.prec = prec ; res.ap = NaN ; res.ap_auc = ap_auc ;
  if opts.rm_res, delete(res_fn) ; end

% -----------------------------
function ap = VOCap07(rec,prec)
% -----------------------------
% From the PASCAL VOC 2007 devkit
  ap = 0 ;
  for t = 0:0.1:1
    p = max(prec(rec>=t)) ;
    if isempty(p), p=0 ; end
    ap = ap + (p/11) ;
  end

% -----------------------------
function ap = xVOCap(rec,prec)
% -----------------------------
% this function is part of the PASCAL VOC 2011 devkit
  mrec=[0 ; rec ; 1];
  mpre=[0 ; prec ; 0];
  for i=numel(mpre)-1:-1:1
      mpre(i)=max(mpre(i),mpre(i+1));
  end
  i=find(mrec(2:end)~=mrec(1:end-1))+1;
  ap=sum((mrec(i)-mrec(i-1)).*mpre(i));
