import sys

if __name__=="__main__":
    if len(sys.argv) < 3:
        print("USAGE: python %s keyword.list lexicon_nosil.txt"%(sys.argv[0]))
        exit(1)

    fid = open(sys.argv[2], "w")
    for line in open(sys.argv[1]).readlines():
        keyword = line.strip().split()[0]
        fid.writelines(keyword + " " + keyword + "\n")
            
