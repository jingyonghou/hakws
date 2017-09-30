import sys
import base
import re
NUM_SIL_STATES=5
STATE_NUM_PER_PHONE=1
def build_syllable_dictionary(dictionary_file):
    syllable_num_dict = {}
    for line in open(dictionary_file).readlines():
        fields = line.strip().split()
        word_id = fields[0]
        phone_fields = re.split('\.|-', fields[1])
        syll_fields = fields[1].split("-")
        syllable_num_dict[word_id]=[len(syll_fields), len(phone_fields)]
    return syllable_num_dict

def build_num_phones_list(syllable_num_dict, nonsil_txt_list):
    num_phones_list = []
    for x in nonsil_txt_list:
        keywords = x.split("-")
        length = len(keywords)
        num_phones = syllable_num_dict[keywords[0].upper()][1]
        if length > 1:
            num_phones += syllable_num_dict[keywords[1].upper()][1]
        num_phones_list.append(num_phones)
    return num_phones_list

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("USAGE: python %s lang_dir syll.dict topo.txt"%sys.argv[0])
        exit(1)

    fid = open(sys.argv[3], 'w')
    fid.writelines("<Topology>\n")
    #prepare non silence topo
    nonsil_int_file = sys.argv[1] + "/nonsilence.int"
    nonsil_txt_file = sys.argv[1] + "/nonsilence.txt"
    nonsil_int_list = base.build_list(nonsil_int_file)
    nonsil_txt_list = base.build_list(nonsil_txt_file)
    syllable_num_dict = build_syllable_dictionary(sys.argv[2])

    num_phones_list = build_num_phones_list(syllable_num_dict, nonsil_txt_list)

    num_phones_dict = {}
    for i in range(len(nonsil_int_list)):
        phone_num = num_phones_list[i]
        word_int_id = nonsil_int_list[i]
        if not num_phones_dict.has_key(phone_num):
            num_phones_dict[phone_num] = []
        num_phones_dict[phone_num].append(word_int_id)

    for phone_num in num_phones_dict.keys():
        fid.writelines("<TopologyEntry>\n")
        fid.writelines("<ForPhones>\n")
         
        for x in num_phones_dict[phone_num]:
            fid.writelines("%s "%x)
        fid.writelines("\n")
        fid.writelines("</ForPhones>\n")
        for state in range(0, phone_num*STATE_NUM_PER_PHONE):
            statep1 = state + 1
            fid.writelines("<State> %d <PdfClass> %d <Transition> %d %.2f <Transition> %d %.2f </State>\n"%(state,state,state,0.75,statep1,0.25))
        fid.writelines("<State> %d </State>\n"%(phone_num*STATE_NUM_PER_PHONE))
        fid.writelines("</TopologyEntry>\n")


    #prepare silence topo
    sil_int_file = sys.argv[1] + "/silence.int"
    sil_int_list = base.build_list(sil_int_file)

    if (NUM_SIL_STATES > 1):
        transp = 1.0 / (NUM_SIL_STATES-1)
        fid.writelines("<TopologyEntry>\n")
        fid.writelines("<ForPhones>\n")
        for x in sil_int_list:
            fid.writelines("%s "%x)
        fid.writelines("\n")
        fid.writelines("</ForPhones>\n")
        fid.writelines("<State> 0 <PdfClass> 0 ")
        for nextstate in range(0, NUM_SIL_STATES-1):
            fid.writelines("<Transition> %d %.2f "%(nextstate,transp))
        fid.writelines("</State>\n")

        for state in range(1, NUM_SIL_STATES-1):
            fid.writelines("<State> %d <PdfClass> %d "%(state,state));
            for nextstate in range(1, NUM_SIL_STATES):
                fid.writelines("<Transition> %d %.2f "%(nextstate,transp))
            fid.writelines("</State>\n")

        state = NUM_SIL_STATES-1;
        fid.writelines("<State> %d <PdfClass> %d <Transition> %d %.2f <Transition> %d %.2f </State>\n"%(state,state,state,0.75,NUM_SIL_STATES,0.25))
        fid.writelines("<State> %d </State>\n"%(NUM_SIL_STATES))
        fid.writelines("</TopologyEntry>\n")
    else:
        fid.writelines("<TopologyEntry>\n")
        fid.writelines("<ForPhones>\n")
        for x in sil_int_list:
            fid.writelines("%d "%x)
        fid.writelines("</ForPhones>\n")
        fid.writelines("<State> 0 <PdfClass> 0 ")
        fid.writelines("<Transition> 0 0.75 ")
        fid.writelines("<Transition> 1 0.25 ")
        fid.writelines("</State>\n")
        fid.writelines("<State> %d </State>\n"%NUM_SIL_STATES)
        fid.writelines("</TopologyEntry>\n")

    fid.writelines("</Topology>\n")
