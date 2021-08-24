import pandas as pd 
import numpy as np 
import os
import argparse

def make_folder (path):
    try:
        os.makedirs(path)
    except OSError:
        print ("Creation of the directory %s failed" % path)
    else:
        print ("Successfully created the directory %s " % path)
        


if __name__=="__main__":

    parser = argparse.ArgumentParser(prog='format_to_inference.py')
    parser.add_argument('--csv_path', type=str, default='image_test_labels.csv', help='Path where the csv with annotations can be found relative to the terminal path')
    parser.add_argument('--save_path', type=str, default='groundtruths', help='Relative path where the txt files will be saved')
    parser.add_argument('--add_conf_debug', type=bool, default=False, help='Relative path where the txt files will be saved')
    opt = parser.parse_args()

    add_conf = opt.add_conf_debug
    
    csv_path = opt.csv_path

    df = pd.read_csv(csv_path , index_col=0)

    unique_img = df.index.unique().values ## unique image names

    path_save = opt.save_path
    make_folder (path_save)

    if add_conf:
        cols_to_save = ["class", "conf_score", "xmin" , "ymin" , "xmax", "ymax"]
    else:
        cols_to_save = ["class", "xmin" , "ymin" , "xmax", "ymax"]

    for im in unique_img:
        ## slice the dataframe and copy its content
        df_filt = df[df.index == im].copy()
        if add_conf:
            df_filt["conf_score"] = np.full(shape=(df_filt.shape[0] , 1) , fill_value=0.5 , dtype=float)
        df_filt = df_filt[cols_to_save] #extract the necessary columns
        # print(df_filt.head())
        
        ## Save the dataframe into a txt file 
        im_name = im.split(".jpg")[0]
        im_path = os.path.join(path_save , im_name + ".txt")   
        df_filt.to_csv(im_path , sep=" ", header = False , index=False)

    