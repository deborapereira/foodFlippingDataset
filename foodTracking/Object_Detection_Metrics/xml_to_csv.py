"""Creates csv files from the dataset splited into folders.
    Each csv file contains a description of all labels of the dataset

Expected tree
root_dir
    - train
        - *.xml
        - *.jpg
    - val
        - *.xml
        - *.jpg

Example usage:
    python xml_to_csv.py \
        --root_dir= "./output" \
        --dataset= "train,test"
"""

import os, glob, pathlib
import pandas as pd

from absl import flags, app
from pascal_voc_tools._xml_parser import XmlParser
from progress.bar import IncrementalBar

flags.DEFINE_string('root_dir', './output', 'Root directory to splited dataset folders')
flags.DEFINE_list('dataset', 'train,test', 'Relative path to the folders with the dataset')
FLAGS = flags.FLAGS

def xml_to_csv(path:str):
    xml_list = glob.glob(os.path.join(path,'*.xml'))
    obj_list = []

    bar = IncrementalBar('Processing XML files... ', max = len(xml_list), 
                         suffix='%(percent)d%% [%(index)d/%(max)d] \t %(filename)s')
    for xml_file in xml_list:
        bar.filename = pathlib.Path(xml_file).stem
        bar.next()

        xml_info = XmlParser().load(xml_file)
        for obj in xml_info['object']:
            value = (pathlib.Path(xml_file).stem + ".jpg",
                     int(xml_info['size']['width']),
                     int(xml_info['size']['height']),
                     obj['name'],
                     int(float(obj['bndbox']['xmin'])),
                     int(float(obj['bndbox']['ymin'])),
                     int(float(obj['bndbox']['xmax'])),
                     int(float(obj['bndbox']['ymax']))
                     )
            obj_list.append(value)
    bar.finish()

    column_name = ['filename', 'width', 'height', 'class', 'xmin', 'ymin', 'xmax', 'ymax']
    xml_df = pd.DataFrame(obj_list, columns=column_name)
    return xml_df

def main(_):
    root_dir = pathlib.Path(FLAGS.root_dir)
    if not root_dir.is_dir():    
        raise ValueError('root_dir = {} is not a folder'.format(root_dir))

    for folder in FLAGS.dataset:
        image_path = pathlib.Path(os.path.join(root_dir, folder))
        print("Processing " + image_path.parts[-1])
        if not image_path.is_dir():
           raise ValueError('{} is not a folder'.format(image_path))

        xml_df = xml_to_csv(image_path)
        xml_df.to_csv(os.path.join(root_dir,'image_{}_labels.csv'.format(image_path.parts[-1])), 
                      index=None)

if __name__ == '__main__':
    app.run(main)
