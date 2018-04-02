### AFEW 3.0


This folder provides a function to construct an `imdb` for the AFEW 3.0 dataset
described in the following paper:

```
Dhall, A., Goecke, R., Joshi, J., Hoey, J., & Gedeon, T. (2016, October).
Emotiw 2016: Video and group-level emotion recognition challenges.
In Proceedings of the 18th ACM International Conference on Multimodal
Interaction (pp. 427-432). ACM.
```

This dataset was released as part of the Emotiw 2016 challenge.  The dataset
statistics are as follows:

| Emotion  | Train | Val | Test |
|----------|-------|-----|------|
| Angry    | 133   | 64  | -    |
| Disgust  | 74    | 40  | -    |
| Fear     | 81    | 46  | -    |
| Happy    | 150   | 63  | -    |
| Neutral  | 144   | 63  | -    |
| Sad      | 117   | 61  | -    |
| Surprise | 74    | 46  | -    |
| Totals   | 773   | 383 | 593  |

The test set was extended from the previous version of AFEW to include examples
from reality TV shows (there are no such examples in the training set).

The baseilne performance reported by the challenge organisers with LBP-TOP
features was `38.81%` on the val set and `40.47` on the test set.
