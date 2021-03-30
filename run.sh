#!/bin/bash
source activate kaldi
mkdir /storage/data
rm -rf /storage/lost+found
jupyter notebook --ip=0.0.0.0 --no-browser --allow-root