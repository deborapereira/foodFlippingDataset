## PROCEDURE


Convert the groundtruth from XML to CSV:
- cd Object_Detection_Metrics
- python xml_to_csv.py --root_dir="test_dataset_and_test_results/ground_truths_xml_files" --dataset="chicken,eggplant,hamburger,zucchini"
Generate the csv file

From the Object-Detection-Metrics folder run the "format_to_inference.py" and give as input the generated csv file. It will convert the csv to a txt format:
- mkdir test_dataset_and_test_results/objects_ground_truths_txt_files/<food>
- python format_to_inference.py --csv_path="test_dataset_and_test_results/ground_truths_xml_files/image_<food>_labels.csv" --save_path="test_dataset_and_test_results/objects_ground_truths_txt_files/<food>"  #  <food> = zucchini / chicken / eggplant / hamburger

Run the "get_labels_from_AllDetections.py" to convert the detection to a txt format. Change some of the variables in the code, set paths and name of files:
- python get_labels_from_AllDetections.py

Merge all the groundtruth folders in the same folder. Do the same for the detection folders.

Change in the "Calculate_metrics.py" the paths to the groundtruth and detection data.

Run the code "Calculate_metrics.py" to get the metrics:
- python Calculate_metrics.py
