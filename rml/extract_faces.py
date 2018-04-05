# -*- coding: utf-8 -*-
"""Script to extract faces from RML datsaet using the dlib frontal
detector (and optionally align them using Adrian Rosebrock's library,
which can be found here: https://github.com/jrosebr1/imutils)

"""
import matplotlib
matplotlib.use('Agg') # avoids backend bug

import os
import sys
ar_path = os.path.expanduser('~/coding/libs/ar-imutils')
sys.path.insert(0, ar_path)

import matplotlib.pyplot as plt

# import the necessary packages
from imutils.face_utils import FaceAligner
from imutils.face_utils import rect_to_bb
import argparse
import imutils
from os.path import join as pjoin
from tqdm import tqdm
import dlib
from scipy.misc import imsave
import cv2
from zsvision.zs_utils import get_img_paths_in_subdirs
from zsvision.zs_iterm import zs_dispFig

# defaults (can be overriden below)
rml_frame_dir = os.path.expanduser('~/data/datasets/rml/frames')
model = os.path.expanduser('~/data/models/dlib/shape_predictor_68_face_landmarks.dat')

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-p", "--shape-predictor",default=model,
               help="path to facial landmark predictor")
ap.add_argument("--subset", default='Train', help="subset to process")
ap.add_argument("--rml_frame_dir", default=rml_frame_dir, help="rml frame directory")
ap.add_argument('--face-width', default=224, help='width of face')
ap.add_argument('--align', action='store_true', default=False, help='align faces')
ap.add_argument('--debug', action='store_true',
                default=False, help='run in debug mode')
args = vars(ap.parse_args())

def show_im(im_cv2, title_str):
    """Quick image visualiser

    Args:
        im_cv2 (ndarray): input image in BGR format
        title_str (str): title header
    """
    fig = plt.figure(frameon=False)
    ax = plt.Axes(fig, [0., 0., 1., 1.])
    ax.axis('off')
    fig.add_axes(ax)
    im = im_cv2[:,:,::-1]
    ax.imshow(im)
    plt.title(title_str)
    zs_dispFig()

def find_best_face(im, detector, align_face=False):
    """find the best available face with the dlib detector and align
    via a simple similarity transform

    Args:
        im (ndarray): image containing one or more faces
        detector (dlib object): frontal face detector
        align_face (bool): whether to perform basic face alignment
    """
    im = imutils.resize(im, width=800)
    gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
    rects = detector(gray, 2)
    if args['debug']:
        show_im(im, 'orig')
    if len(rects) == 0:
        return None
    else:
        rect = rects[0] # take most confident
        # extract the ROI of the *original* face, then align the face
        # using facial landmarks
        (x, y, w, h) = rect_to_bb(rect)
        out_face = imutils.resize(im[y:y + h, x:x + w],
                                  width=args['face_width'])
        if align_face:
            out_face = fa.align(im, gray, rect)
        if args['debug']:
            show_im(out_face, 'out face') # display the output images
        return out_face

# initialize dlib's face detector (HOG-based) and then create
# the facial landmark predictor and the face aligner
# code from here (https://www.pyimagesearch.com/2017/05/22/face-alignment-with-opencv-and-python/)
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(args["shape_predictor"])
fa = FaceAligner(predictor, desiredFaceWidth=args['face_width'])

img_list = get_img_paths_in_subdirs(args['rml_frame_dir'])

# store in the same structure as the provided Faces directory
for img_path in tqdm(img_list):
    src_path = img_path
    # lazily assumes that frame directory is called 'frames' i.e. that
    # the split_into_frames.py script in this directory was used
    dest_path = src_path.replace('frames', 'faces')
    if os.path.exists(dest_path):
        print('found target at {}, skipping..'.format(dest_path))
        continue
    parent = os.path.dirname(dest_path)
    if not os.path.exists(parent):
        os.makedirs(parent)
    im = cv2.imread(src_path)
    best_face = find_best_face(im, detector, align_face=args['align'])
    if best_face is not None:
        # show_im(best_face, 'best')
        imsave(dest_path, best_face[:,:,::-1]) # save as RGB
        # print('saving face to {}'.format(dest_path))
