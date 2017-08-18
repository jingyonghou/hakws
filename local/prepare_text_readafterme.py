import sys

def build_text_dict(text_dict_file):
    text_dict = {}
    for line in open(text_dict_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        text = " ".join(fields[1:])
        text_dict[text_id] = text
    return text_dict

if __name__=="__main__":
    if(len(sys.argv) < 4):
        print("USAGE: python " + sys.argv[0] + "text_dict wav_id_file text_file")
        exit(1)
    text_dict = build_text_dict(sys.argv[1])
    fid = open(sys.argv[3], "w")
    for x in open(sys.argv[2]).readlines():
        text_id = "_".join(x.strip().split("_")[0:2])
        fid.writelines("%s\t%s\n"%(x.strip(), text_dict[text_id]))
    fid.close()
