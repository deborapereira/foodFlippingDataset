import _init_paths
from BoundingBox import BoundingBox
from BoundingBoxes import BoundingBoxes
from Evaluator import *
from utils import BBFormat
from Metric_gen_fun import extract_metrics_custom
import json

if __name__ == "__main__":

    gtFormat = "xyrb" #ValidateFormats(args.gtFormat, '-gtformat', errors)
    detFormat = "xyrb" #ValidateFormats(args.detFormat, '-detformat', errors)
    # Groundtruth folder
    gtFolder = "test_dataset_and_test_results/objects_ground_truths_txt_files/all"
    detFolder = "test_dataset_and_test_results/objects_detected_txt_files/all"
    imgSize = (0, 0)
    gtCoordType = CoordinatesType.Absolute
    detCoordType = CoordinatesType.Absolute
    iouThreshold = 0.5

    all_metrics, per_class_metrics = extract_metrics_custom(gtFolder , detFolder , gtFormat , detFormat, iouThreshold, gtCoordType, detCoordType, imgSize)

    print("Average Metrics" , all_metrics)
    print("Per Class Metrics" , per_class_metrics)

    merge_dict = {"Average Metrics": all_metrics, "Per Class Metrics":per_class_metrics}
    with open('test_dataset_and_test_results/Results_Metrics.txt', 'w') as outfile:
        json.dump(merge_dict, outfile)