### rml


This folder provides a function to construct an `imdb` for the rml emotion
recognition dataset described in the following paper:

```

@inproceedings{wang2004investigation,
  title={An investigation of speech-based human emotion recognition},
  author={Wang, Yongjin and Guan, Ling},
  booktitle={Multimedia Signal Processing, 2004 IEEE 6th Workshop on},
  pages={15--18},
  year={2004},
  organization={IEEE}
}

http://www.rml.ryerson.ca/rml-emotion-database.html
```

We use the provided `rml-1` and `rml-2` splits for training and validation,
which contain five and three speakers respectively.

The dataset statistics are as follows:

| Emotion  | Train | Val |
|----------|-------|-----|
| Angry    | 66    | 54  |
| Disgust  | 67    | 53  |
| Fear     | 67    | 53  |
| Happy    | 73    | 47  |
| Sad      | 66    | 54  |
| Surprise | 68    | 52  |
| Totals   | 407   | 313 |

The average clip is `4.94` seconds long.
