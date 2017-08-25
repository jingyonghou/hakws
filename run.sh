#!/bin/bash

. ./cmd.sh
. ./path.sh
stage=8
nj=20

xiaoying_dir=/home/disk1/jyhou/data/XiaoYing_STD
train=train
if [ $stage -le 0 ]; then
    #prepare training data for train the hmm-gmm model 
    local/prepare_xiaoying_keywords.sh $xiaoying_dir

    #prepare test data for test of KWS system
    local/prepare_xiaoying_search_data.sh 
    #prepare dictionary file
    local/prepare_dict.sh
    local/prepare_lm.sh
fi

mfcc_dir=mfcc
if [ $stage -le 1 ]; then
    for x in keywords_60_100 keywords_native data_15_30 data_40_55 data_65_80;
    do
        utils/copy_data_dir.sh  data/$x $mfcc_dir/$x; 
        rm $mfcc_dir/$x/{feats,cmvn}.scp
        steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj $mfcc_dir/$x \
            $mfcc_dir/$x/log $mfcc_dir/$x/data
        steps/compute_cmvn_stats.sh $mfcc_dir/$x $mfcc_dir/$x/log \
            $mfcc_dir/$x/data
    done
fi

fbank_dir=fbank
if [ $stage -le 2 ]; then
    for x in keywords_60_100 keywords_native data_15_30 data_40_55 data_65_80;
    do
        utils/copy_data_dir.sh  data/$x $fbank_dir/$x; 
        rm $fbank_dir/$x/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 \
            $fbank_dir/$x $fbank_dir/$X/log $fbank_dir/$x/data || exit 1;
        steps/compute_cmvn_stats.sh $fbank_dir/$x $fbank_dir/$x/log \
            $fbank_dir/$x/data || exit 1;
    done
fi

fbank_dir=fbank
nnet=../swbd_xy_egs/exp/xiaoying_train_nodup_200_4096_0.0005_0.9-nnet5uc-part2/
sbnf="sbnf1"
if [ $stage -le 3 ]; then
    for x in keywords_60_100 keywords_native data_15_30 data_40_55 data_65_80;
    do
        bn_dir=$sbnf/$x
        mkdir -p $bn_dir
        steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj $nj $bn_dir \
            $fbank_dir/$x $nnet $bn_dir/log $bn_dir/data
        steps/compute_cmvn_stats.sh $bn_dir/ $bn_dir/log $bn_dir/data
    done
fi

#mono training
feature_dir="mfcc"
if [ $stage -le 8 ]; then
    utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false data/local/dict \
         "<SIL>" data/local/lang data/lang
    python local/prepare_topo.py data/lang/phones info/syll.dict data/lang/topo
    local/train_mono.sh --nj $nj --cmd "$train_cmd" \
        --cmvn-opts "--norm-means=false --norm-vars=false" \
        --totgauss 1000 \
        $feature_dir/keywords_60_100 data/lang exp/mono_keywords_60_100

   #steps/train_mono.sh --nj $nj --cmd "$train_cmd" \
   #    --cmvn-opts "--norm-means=false --norm-vars=false" \
   #    --totgauss 1000 \
   #    $train_dir/keywords_native data/lang exp/mono_keywords_native
fi


#build decode graph for each keyword
nj=20
model_dir="exp/mono_keywords_60_100"
decode_dir="exp/decode"
if [ $stage -le 8 ]; then
    export LC_ALL=C
    lang="data/lang"
    mkdir -p $decode_dir
    
    cp $model_dir/tree $decode_dir/tree
    cp $model_dir/final.mdl $decode_dir/final.mdl
    cp $model_dir/cmvn_opts $decode_dir/cmvn_opts 
    cat info/keywords.list |uniq|sort > $decode_dir/keywords_sort.list
    
    oov=`cat $lang/oov.int` || exit 1;
    keywords_list=$decode_dir/keywords_sort.list
    tras=$decode_dir/keywords.tras
    paste $keywords_list $keywords_list > $tras
    utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt $decode_dir/keywords.tras > $decode_dir/keywords.tras.int
    tras=$decode_dir/keywords.tras.int
    mkdir -p tmp/
    python local/split.py $tras tmp/ $nj
    graphs=$decode_dir/graphs.JOB.fsts
    python local/convert_lexicon.py $lang/words.txt \
        $lang/phones.txt data/local/dict/lexicon.txt info/lexicon.int
    run.pl JOB=1:$nj log/make_keywords_graphs.JOB.log \
        compile-keyword-graphs --read-disambig-syms=$lang/phones/disambig.int \
        $decode_dir/tree $decode_dir/final.mdl  info/lexicon.int "ark:tmp/keywords.tras.intJOB" ark:$graphs
fi

#decode
if [ $stage -le 8 ]; then
    for x in data_65_80; do 
        result_dir=results/${x}_keywords_60_100_word
        mkdir -p $result_dir
        local/akws_i.sh --scale_opts "--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1" \
                --nj $nj $feature_dir/$x $decode_dir $result_dir
    done
fi

#evaluate
keyword_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
data_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
#ctm_file="/mnt/jyhou/workspace/my_egs/xiaoying_native/s5c/exp/nn_xiaoying_native_ali/ctm"
text_file="info/text.dict"
syllable_num_file="info/keyword_syllable_num.txt"
keyword_list_file="info/keywords.list"

if [ $stage -le 8 ]; then
    for x in data_65_80;
    do
       
       result_dir=results/${x}_keywords_60_100_word/
       test_list_file=$feature_dir/$x/wav.scp
       echo $result_dir
       echo "python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file"
             python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file
    done
fi

