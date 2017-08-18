import os
#===================system related====================#
def get_file(path, suffix):
    file_list = []
    items = os.listdir(path)
    for x in items:
        if os.path.isfile(path + "/" + x) and x.endswith(suffix):
            file_list.append(path + "/" + x)
            #print(path + "/" + x)
        elif os.path.isdir(path + "/" + x):
            file_list += get_file(path + "/" + x, suffix)
    return file_list

def mkdir(path):
    is_exists = os.path.exists(path)
    if not is_exists:
        os.makedirs(path)

def remove_data_suffix(file_list, suffix):
    new_file_list = []
    for x in file_list:
        new_file_list.append(x.replace(suffix, ''))
    return new_file_list

def remove_root_dir(file_list, root_dir):
    new_file_list = []
    for x in file_list:		
        x_new = x.replace(root_dir, '')
        new_file_list.append(x_new)
    return new_file_list

#list related		
def build_list(list_file):
    list_ = []
    for line in open(list_file, "rb").readlines():
        list_.append(line.strip().split()[0])
    return list_

def build_scp_dict(scp_file):
    scp_dict = {}
    for line in open(scp_file).readlines():
        fields = line.strip().split()
        f_id = fields[0]
        f_value = " ".join(fields[1:])
        scp_dict[f_id] = f_value
    return scp_dict

    
