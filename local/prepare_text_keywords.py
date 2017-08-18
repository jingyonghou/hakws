import sys

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("USAGE: python %s wav.id text"%sys.argv[0])
        exit(1)

    fid = open(sys.argv[2], "w")
    for line in open(sys.argv[1]).readlines():
        wav_id = line.strip().split()[0]
        keyword = wav_id.split("_")[0]
        fid.writelines("%s %s\n"%(wav_id,keyword))

