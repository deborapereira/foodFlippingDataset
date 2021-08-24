import numpy as np 
import os
import sys
import pandas as pd 
import glob

def make_folder (path):
    try:
        os.makedirs(path)
    except OSError:
        print ("Creation of the directory %s failed" % path)
    else:
        print ("Successfully created the directory %s " % path)

if __name__ == "__main__":
    food = "zucchini" #chicken; eggplant; hamburger; zucchini
    path_to_allDetections = "test_dataset_and_test_results/algorithm_outputs_csv_files/zuch.csv" # chic.csv; eggp.csv; hamb.csv; zuch.csv
    path_to_gtLabels = "test_dataset_and_test_results/objects_ground_truths_txt_files/" + food # chicken; eggplant; hamburger; zucchini
    class_name = food  # chicken; eggplant; hamburger; zucchini
    detection_folder = "test_dataset_and_test_results/objects_detected_txt_files/" + food # chicken; eggplant; hamburger; zucchini
    obj_cat = 3 # 1; 4; 2; 3

    ## Import the csv file where all the predictions are recorded
    df_all = pd.read_csv(path_to_allDetections)

    ## Import the csv file of the groundtruth only
    gt_files = glob.glob(path_to_gtLabels + "/*.txt")

    ## Prefix of the images
    ## Create Directories to store the txt file
    make_folder(detection_folder)

    ## Loop through the GroundTruth Images and find its corresponding Detection
    for idx , gt_img in enumerate(gt_files[:]):
        
        df_detect = pd.DataFrame(columns=["class" , "conf_threshold" , "x_min" , "y_min" , "x_max" , "y_max"])

        frame_num = gt_img.split("_")[-1][:-4]
        
        df_all_filter = df_all[ df_all["frame_num"] <= int(frame_num)]

        last_frame = df_all_filter["frame_num"].unique()[-1]
        
        df_all_filter = df_all[ df_all["frame_num"] == last_frame]
        df_all_filter = df_all_filter[ df_all_filter["obj_cat"] == obj_cat]

        df_detect["class"] = [class_name]*df_all_filter.shape[0]
        df_detect["conf_threshold"] = df_all_filter[" score"].values / 100
        df_detect["x_min"] = df_all_filter["startY"].values
        df_detect["y_min"] = df_all_filter["startX"].values
        df_detect["x_max"] = df_all_filter["endY"].values
        df_detect["y_max"] = df_all_filter["endX"].values

        file_name = gt_img.split("/")[-1]
        save_path = detection_folder + "/" + file_name
        print(save_path)
        df_detect.to_csv( save_path ,sep = " ", index = False ,header = False)