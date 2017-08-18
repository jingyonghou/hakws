export LC_ALL=C

xiaoying__dir=$1
for x in keywords_60_100 keywords_native;
do
    data_dir=$1/$x
    mkdir -p data/local/$x/
    mkdir -p data/$x
    find $data_dir -name *.wav > data/local/$x/wav.list
    sed -e "s:^${data_dir}/::" -e "s:.wav$::" -e "s: :-:" data/local/$x/wav.list > data/local/$x/wav.id
    # prepare text file
    python local/prepare_text_keywords.py data/local/$x/wav.id data/local/$x/text
    cat data/local/$x/text |sort > data/$x/text
    paste data/local/$x/wav.id data/local/$x/wav.list |sort > data/$x/wav.scp
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    utils/fix_data_dir.sh data/$x
done
