#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

# Computes training alignments using a model with delta or
# LDA+MLLT features.

# If you supply the "--use-graphs true" option, it will use the training
# graphs from the source directory (where the model is).  In this
# case the number of jobs must match with the source directory.


# Begin configuration section.
nj=4
cmd=run.pl
# Begin configuration.
scale_opts="--transition-scale=1.0 --acoustic-scale=1.0 --self-loop-scale=1.0"

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: local/akws_i.sh <data-dir> <decode> <result-dir>"
   echo "e.g.:  steps/align_si.sh data/train data/lang exp/tri1 exp/tri1_ali"
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>                           # config containing options"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

data=$1
decode_dir=$2
result_dir=$3

splice_opts=`cat $decode_dir/splice_opts 2>/dev/null`
cmvn_opts=`cat $decode_dir/cmvn_opts 2>/dev/null`
delta_opts=`cat $decode_dir/delta_opts 2>/dev/null`

feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:$data/feats.scp ark:- | add-deltas $delta_opts ark:- ark:- |"

echo "iterating-viterbi-decoding $decode_dir/final.mdl ark:$decode_dir/graphs.fsts '$feats' $result_dir/"
$cmd JOB=1:$nj log/make_akws.JOB.log \
iterating-viterbi-decoding $scale_opts $decode_dir/final.mdl ark:$decode_dir/graphs.JOB.fsts "$feats" $result_dir/


