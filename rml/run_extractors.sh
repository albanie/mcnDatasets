# speed things up a bit
NUM_WOKERS=20
PYTHON_BINARY=~/local/anaconda3/envs/pt3/bin/python

let "SEQ_BOUND = $NUM_WOKERS - 1"

for ii in $(seq 0 ${SEQ_BOUND})
  do echo starting job $ii;
   $PYTHON_BINARY extract_faces.py --num_workers $NUM_WOKERS --worker_id $ii &
done
