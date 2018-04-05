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

Subjects: 44, total vids: 1293

I've chosen to arbitrarily assign subjects 1 - 30 as training, and 31 - 44
as validation

| Emotion  | All   | Val |
|----------|-------|-----|
| Angry    | 146   | 70  |
| Disgust  | 146   | 70  |
| Fear     | 146   | 70  |
| Happy    | 143   | 70  |
| Sad      | 146   | 70  |
| Surprise | 146   | 70  |

| Totals   | 873   | 420 |
