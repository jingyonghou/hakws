mkdir -p data/local/dict
python local/prepare_lexicon.py info/keywords.list info/lexicon_nosil.txt
echo "<SIL> SIL" > info/lexicon_sil.txt
cp info/lexicon_nosil.txt data/local/dict/lexicon_words.txt
cat info/lexicon_sil.txt info/lexicon_nosil.txt > data/local/dict/lexicon.txt

echo "SIL" > data/local/dict/silence_phones.txt
echo "SIL" > data/local/dict/optional_silence.txt

# nonsilence phone
cut -d" " -f2- info/lexicon_nosil.txt >  data/local/dict/nonsilence_phones.txt

