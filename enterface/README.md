### enterface


This folder provides a function to construct an `imdb` for the enterface dataset
described in the following paper:

```
@inproceedings{martin2006enterface,
  titludio-visual emotion database},
  author={Martin, Olivier and Kotsia, Irene and Macq, Benoit and Pitas, Ioannis},
  booktitle={Data Engineering Workshops, 2006. Proceedings. 22nd International Conference on},
  pages={8--8},
  year={2006},
  organization={IEEE}
}
```

The statistics in the version I have are as follows (these are slightly
larger than the numbers reported in the publication):

This data     - Subjects: 44, total vids: 1293
Original data - Subjects: 42, total vids: 1166

I've chosen to arbitrarily assign subjects 1 - 30 as training, and 31 - 44
as validation.

| Emotion  | All   | Val |
|----------|-------|-----|
| Angry    | 146   | 70  |
| Disgust  | 146   | 70  |
| Fear     | 146   | 70  |
| Happy    | 143   | 70  |
| Sad      | 146   | 70  |
| Surprise | 146   | 70  |

| Totals   | 873   | 420 |

Note that the original version of the dataset uses spaces in the directory names
which can cause issues, so it's easier to swap them for hyphens before running
the processing (e.g. `find . -name "* *" | rename 's/ /-/g'`).
