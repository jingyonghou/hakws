import numpy as np
import sys
import base

TOP=5
matrix_list = ["all keyword", "unigram keyword", "bigram keyword"]

def m_norm(scorelist):
    hist, bin_edges = np.histogram(scorelist,40)
    index = hist.argmax();

    peak = (bin_edges[index] + bin_edges[index+1])/2

    slist_peak = np.array([x for x in scorelist if x >= peak])
    scorelist = (scorelist - peak)/slist_peak.std()

    return scorelist

def z_norm(scorelist):
    #scorelist = (np.array(scorelist)-min(scorelist))/(max(scorelist)-min(scorelist))
    mean = np.mean(scorelist)
    std  = np.std(scorelist)
    scorelist = (np.array(scorelist)-mean)/std
    return scorelist

def relevant(query, text_id, occurance_dict):
    if query in occurance_dict[text_id]:
        return True
    return False

def build_occurance_dict(keywords_list, text_file):
    keywords_list_uniq = set()
    for keyword in keywords_list:
        keywords_list_uniq.add(keyword.strip().split("_")[0])
    occurance_dict = {}
    for line in open(text_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        single_words = fields[1:]
        occurance_dict[text_id] = set()
        for i in range(len(single_words)):
            if single_words[i] in keywords_list_uniq:
                occurance_dict[text_id].add(single_words[i])

        for i in range(len(single_words)-1):
            word1 = single_words[i]
            word2 = single_words[i+1]
            phrase = word1 + "-" + word2
            if phrase in keywords_list_uniq:
                occurance_dict[text_id].add(phrase)
    return occurance_dict

def build_syllable_num_dict(syllable_num_file):
    syllable_num_dict = {}
    for line in open(syllable_num_file).readlines():
        fields = line.strip().split()
        keyword = fields[0]
        syllable_num = int(fields[1])
        syllable_num_dict[keyword]=syllable_num
    return syllable_num_dict

def evaluate(costlist, querylist, doclist, relevant_dict, syllable_num_dict):
    evaluate_matrix = {}
    for x in matrix_list:
        evaluate_matrix[x] = []
    
    for i in range(len(querylist)):
        ranklist = np.array(costlist[i]).argsort()
        Precision = []
        num_rele = 0.0
        sum_precision = 0.0

        for j in range(len(ranklist)):
            keyword_id = querylist[i].strip().split("_")[0]
            doc_id = "_".join(doclist[ranklist[j]].strip().split("_")[:-1])
            isRele = False
            if relevant(keyword_id, doc_id, relevant_dict):
                num_rele += 1
                isRele = True
            Precision.append(num_rele/(j+1))
            if isRele == True:
                sum_precision += Precision[-1]
        N = int(num_rele)
        if N == 0:
            continue

        if (keyword_id.find("-") > 0):
            evaluate_matrix["bigram keyword"].append([sum_precision/N, Precision[N-1], Precision[TOP-1]])
        else:
            evaluate_matrix["unigram keyword"].append([sum_precision/N, Precision[N-1], Precision[TOP-1]])

        evaluate_matrix["all keyword"].append([sum_precision/N, Precision[N-1], Precision[TOP-1]])
        
        #print(str(APset[-1]) + "\t" + str(PatNset[-1]) + "\t" + str(Pat10set[-1]))
    return evaluate_matrix

if __name__=="__main__":
    if len(sys.argv) < 6:
        print("USAGE: python %s result_dir keywordlist testlist textfile syllable_num_file"%sys.argv[0])
        exit(1)
    
    result_dir =  sys.argv[1]
    keyword_list = base.build_list(sys.argv[2])
    test_list = base.build_list(sys.argv[3])
    occurance_dict = build_occurance_dict(keyword_list, sys.argv[4])
    syllable_num_dict =build_syllable_num_dict(sys.argv[5])

    cost_list = []
    for keyword in keyword_list:
        result_fid = open(result_dir + keyword.strip() + ".RESULT")
        result_list = result_fid.readlines()
        result_fid.close()
        
        score_list = []
        for res in result_list:
            score = float(res.strip().split()[0])
            score_list.append(score)
        cost_list.append(score_list)
    evaluate_matrix = evaluate(cost_list, keyword_list, test_list, occurance_dict, syllable_num_dict)
    for x in matrix_list:
        output = np.array(evaluate_matrix[x]).mean(axis=0)
        MAP = output[0]
        PatN = output[1]
        Pat5 = output[2]
        print('%s: MAP=%.3f PatN=%.3f Pat5=%.3f'%(x, MAP, PatN, Pat5))

