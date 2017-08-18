import sys
import base

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("USAGE: python %s word.txt phones.txt lexicon.txt lexicon.in"%sys.argv[0])
        exit(1)

    word_dict = base.build_scp_dict(sys.argv[1])
    phones_dict = base.build_scp_dict(sys.argv[2])
    lexicon_list = open(sys.argv[3]).readlines()

    fid = open(sys.argv[4], "w")
    fid.writelines("0 0\n")
    for line in lexicon_list:
        fields = line.strip().split()
        word = fields[0]
        fid.writelines(word_dict[word])
        for phone in fields[1:]:
            fid.writelines(" %s"%(phones_dict[phone]))
        fid.writelines("\n")
    fid.close()

