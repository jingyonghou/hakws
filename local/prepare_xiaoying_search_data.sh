export LC_ALL=C


for x in data_15_30 data_40_55 data_65_80; 
do
    data_dir=/home/disk1/jyhou/data/XiaoYing_STD/${x}_final
    mkdir -p data/local/$x/
    
    find ${data_dir}/ -name *.wav > data/local/$x/wav.list
    sed -e "s:^$data_dir/::" -e "s:.wav$::" data/local/$x/wav.list > \
        data/local/$x/wav.id
    python local/prepare_text_readafterme.py info/text.dict data/local/$x/wav.id \
        data/local/$x/text
    paste data/local/$x/wav.id data/local/$x/wav.list > data/local/$x/wav.scp
    
    mkdir -p data/$x
    cat data/local/$x/wav.scp |sort > data/$x/wav.scp
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    cat data/local/$x/text |sort > data/$x/text
    utils/fix_data_dir.sh data/$x
done
