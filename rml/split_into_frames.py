# -*- coding: utf-8 -*-
"""Script to convert the rml dataset into individual frames

http://www.rml.ryerson.ca/rml-emotion-database.html
"""
import os
import subprocess
import glob
from zsvision.zs_utils import get_img_paths_in_subdirs
from os.path import join as pjoin

# set as appropriate
FPS = 4 # desired framerate for extracted frames
FFMPEG_BIN = os.path.expanduser('~/local/bin/ffmpeg') # ffmpeg binary

def split_video(video_path, target_frame_dir, fps):
    """
    splits videos into frames with ffmpeg

    Args:
        video_path (string): path to video file
        fps (float): the number of frames per second
        target_frame_dir (string): path to the directory
                where the frames will be stored

    NOTE: By default, runs single threaded to avoid titan killing the process
    """

    if not os.path.exists(target_frame_dir):
         os.makedirs(target_frame_dir)
    ffmpeg_str = ('{} -i {} -r {} -threads 1 {}/%07d.jpg')

    command = ffmpeg_str.format(FFMPEG_BIN, video_path, fps, target_frame_dir)
    return subprocess.call(command, shell=True)


data_dir = os.path.expanduser('~/data/datasets/rml')
frame_dir = pjoin(data_dir, 'frames')
if not os.path.exists(frame_dir):
    os.makedirs(frame_dir)

roots = glob.glob(pjoin(data_dir, '*'))

for root_dir in roots:
    num_base_tokens = len(root_dir.split('/'))
    subs = glob.glob(pjoin(root_dir, '*'))
    for sub in subs:
        vids = get_img_paths_in_subdirs(sub, suffix='avi')
        for vid in vids:
            tokens = vid.split('.')[0].split('/')
            dest_dir = pjoin(frame_dir, '/'.join(tokens[num_base_tokens-1:]))
            print('extracting {} to {}'.format(vid, dest_dir))
            split_video(vid, dest_dir, FPS)
