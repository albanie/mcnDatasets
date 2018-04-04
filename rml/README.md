### rml


This folder provides a function to construct an `imdb` for the rml emotion
recognition dataset described in the following paper:

```
@article{xie2013multimodal,
  title={Multimodal information fusion of audio emotion recognition based on kernel entropy component analysis},
  author={Xie, Zhibing and Guan, Ling},
  journal={International Journal of Semantic Computing},
  volume={7},
  number={01},
  pages={25--42},
  year={2013},
  publisher={World Scientific}
}
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
from reality TV shows (there are no such examples in the training set). The 
baseilne performance reported by the challenge organisers with LBP-TOP
features was `38.81%` on the val set and `40.47%` on the test set.
