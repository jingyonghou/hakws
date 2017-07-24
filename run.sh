#!/bin/bash

. ./cmd.sh
. ./path.sh
stage=4
nj=20

xiaoying_dir=/home/disk1/jyhou/data/XiaoYing_STD
train=train
if [ $stage -le 0 ]; then
    #prepare training data for train the hmm-gmm model 
    local/prepare_xiaoying_keywords.sh $xiaoying_dir
    #prepare dictionary file
    local/prepare_dict.sh
    utils/prepare_lang.sh --position-dependent-phones false data/local/dict "<SIL>" data/local/lang data/lang
    python local/prepare_topo.py data/lang info/syll.dict data/lang/topo
    local/prepare_lm.sh
fi

mfcc_dir=mfcc
if [ $stage -le 1 ]; then
    for x in keywords_60_100 keywords_native;
    do
        utils/copy_data_dir.sh  data/$x $mfcc_dir/$x; rm $mfcc_dir/$x/{feats,cmvn}.scp
        steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj $mfcc_dir/$x $mfcc_dir/$x/log $mfcc_dir/$x/data
        steps/compute_cmvn_stats.sh $mfcc_dir/$x $mfcc_dir/$x/log $mfcc_dir/$x/data
    done
fi

fbank_dir=fbank
if [ $stage -le 2 ]; then
    for x in keywords_60_100 keywords_native;
    do
        utils/copy_data_dir.sh  data/$x $fbank_dir/$x; rm $fbank_dir/$x/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 \
                       $fbank_dir/$x $fbank_dir/$X/log $fbank_dir/$x/data || exit 1;
        steps/compute_cmvn_stats.sh $fbank_dir/$x $fbank_dir/$x/log $fbank_dir/$x/data || exit 1;
    done
fi

fbank_dir=fbank
nnet=/home/disk1/jyhou/my_egs/swbd_xy_egs/exp/xiaoying_train_nodup_200_4096_0.0005_0.9-nnet5uc-part2/
sbnf="sbnf1"
if [ $stage -le 3 ]; then
    for x in keywords_60_100 keywords_native;
    do
        bn_dir=$sbnf/$x
        mkdir -p $bn_dir
        steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj $nj $bn_dir $fbank_dir/$x $nnet $bn_dir/log $bn_dir/data
        steps/compute_cmvn_stats.sh $bn_dir/ $bn_dir/log $bn_dir/data
    done
fi

#mono training
train_dir="sbnf1"
if [ $stage -le 4 ]; then
    steps/train_mono.sh --nj $nj --cmd "$train_cmd" \
        --cmvn-opts "--norm-means=false --norm-vars=false" \
        --totgauss 2000 \
        $train_dir/keywords_60_100 data/lang exp/mono_keywords_60_100

    steps/train_mono.sh --nj $nj --cmd "$train_cmd" \
        --cmvn-opts "--norm-means=false --norm-vars=false" \
        --totgauss 1000 \
        $train_dir/keywords_native data/lang exp/mono_keywords_native
fi
