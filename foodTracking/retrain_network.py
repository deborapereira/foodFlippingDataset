# USAGE
# python retrain_network.py 

import os
import sys
import random
import math
import re
import time
import numpy as np
import cv2
import matplotlib
import matplotlib.pyplot as plt

# Root directory of the project
ROOT_DIR = os.path.abspath("../")

# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library
from mrcnn.config import Config
from mrcnn import utils
import mrcnn.model as modellib
from mrcnn import visualize
from mrcnn.model import log

from xml.etree import ElementTree

from mrcnn import visualize
import mrcnn
from mrcnn.utils import Dataset
from mrcnn.model import MaskRCNN
from numpy import zeros
from numpy import asarray
import colorsys
import argparse
import imutils

from matplotlib import pyplot
from matplotlib.patches import Rectangle
from keras.models import load_model
import os
import tensorflow as tf

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
# Directory to save logs and trained model
MODEL_DIR = os.path.join(ROOT_DIR, "logs")

# Local path to trained weights file 
# original coco NN
#COCO_MODEL_PATH = os.path.join(ROOT_DIR, "mask_rcnn_coco.h5")

#current retrained NN 
COCO_MODEL_PATH = os.path.join(MODEL_DIR, "mask_rcnn_food.h5")

# Download COCO trained weights from Releases if not present
if not os.path.exists(COCO_MODEL_PATH):
	print("coco model not found, download...")
	utils.download_trained_weights(COCO_MODEL_PATH)
	


class FoodConfig(Config):

	# Give the configuration a recognizable name
	NAME = "food"

	# Train on 1 GPU and 8 images per GPU. We can put multiple images on each
	# GPU because the images are small. Batch size used here is 1 (GPUs * images/GPU).
	GPU_COUNT = 1
	IMAGES_PER_GPU = 1

	# Number of classes (including background)
	NUM_CLASSES = 1 + 5	 # background, hamburguer, chicken, zucchini, eggplant, marker
	
	# the large side, and that determines the image shape.
	IMAGE_MIN_DIM = 720
	IMAGE_MAX_DIM = 1024 #1280
    # Use smaller anchors because our image and objects are small
	RPN_ANCHOR_SCALES = (32, 64, 128, 256, 512)  # anchor side in pixels
	# Reduce training ROIs per image because the images are small and have
	# few objects. Aim to allow ROI sampling to pick 33% positive ROIs.
	TRAIN_ROIS_PER_IMAGE = 32
	# Use a small epoch since the data is simple
	STEPS_PER_EPOCH = 200
	# Learning rate
	LEARNING_RATE=0.002
	# use small validation steps since the epoch is small
	VALIDATION_STEPS = 10


		
class FoodDataset(utils.Dataset):
	# load the dataset definitions
	def load_dataset(self, dataset_dir, is_train=True):
		
		self.add_class("food", 1, "chicken")
		self.add_class("food", 2, "hamburger")
		self.add_class("food", 3, "zucchini")
		self.add_class("food", 4, "eggplant")
		self.add_class("food", 5, "marker")
		
		# define data locations for images and annotations
		images_dir = dataset_dir + '.\\ImageSets\\'
		annotations_dir = dataset_dir + '\\Annotations\\'
		
		# Iterate through all files in the folder to 
		#add class, images and annotaions
		for filename in os.listdir(images_dir):
			
			# extract image id
			image_id = filename[:-4]
			
			# skip bad images
			#if is_train and image_id in ['vlcsnap-2020-10-06-09h01m47s971','vlcsnap-2020-10-06-08h59m53s736','vlcsnap-2020-10-06-09h05m19s934','vlcsnap-2020-10-06-09h04m03s264', 'vlcsnap-2020-10-10-16h26m13s991', 'vlcsnap-2020-10-10-16h29m19s103','vlcsnap-2020-10-10-16h33m09s261','vlcsnap-2020-10-10-16h35m33s532','vlcsnap-2020-10-10-16h40m44s462', 'vlcsnap-2020-10-10-16h44m16s571']: #'1','3','4','9','vlcsnap-2020-01-13-15h04m57s873']:
			#	continue
			# skip all images before 150 if we are building the test/val set
			if not is_train and not image_id in  ['vlcsnap-2020-10-06-09h01m47s971','vlcsnap-2020-10-06-08h59m53s736','vlcsnap-2020-10-06-09h05m19s934','vlcsnap-2020-10-06-09h04m03s264', 'vlcsnap-2020-10-10-16h26m13s991', 'vlcsnap-2020-10-10-16h29m19s103','vlcsnap-2020-10-10-16h33m09s261','vlcsnap-2020-10-10-16h35m33s532','vlcsnap-2020-10-10-16h40m44s462', 'vlcsnap-2020-10-10-16h44m16s571', 'vlcsnap-2020-10-13-09h51m23s338', 'vlcsnap-2020-10-13-09h50m35s916', 'vlcsnap-2020-10-13-09h50m10s624', 'vlcsnap-2020-10-13-09h48m34s883', 'vlcsnap-2020-10-13-09h47m26s107', 'vlcsnap-2020-10-13-09h45m53s381', 'vlcsnap-2020-10-13-09h45m02s900', 'vlcsnap-2020-10-13-09h38m27s984', 'vlcsnap-2020-10-13-09h40m28s260', 'vlcsnap-2020-10-13-09h35m58s843', 'vlcsnap-2020-10-13-09h34m56s980', 'vlcsnap-2020-10-10-16h44m07s839', 'vlcsnap-2020-10-06-09h00m22s515']: #['1','3','4','9','vlcsnap-2020-01-13-15h04m57s873']:
				continue
			
			# setting image file
			img_path = images_dir + filename
			
			# setting annotations file
			ann_path = annotations_dir + image_id + '.xml'
			
			# adding images and annotations to dataset
			self.add_image('food', image_id=image_id, path=img_path, annotation=ann_path)
	# extract bounding boxes from an annotation file
	def extract_boxes(self, filename):
		
		# load and parse the file
		tree = ElementTree.parse(filename)
		# get the root of the document
		root = tree.getroot()
		# extract each bounding box
		boxes = list()
		categories = list()
		
		for box in root.findall('.//bndbox'):
			xmin = int(box.find('xmin').text)
			ymin = int(box.find('ymin').text)
			xmax = int(box.find('xmax').text)
			ymax = int(box.find('ymax').text)
			coors = [xmin, ymin, xmax, ymax]
			boxes.append(coors)
		
		for cat in root.findall('.//name'):
			catname = cat.text
			categories.append(catname)
		# extract image dimensions
		width = int(root.find('.//size/width').text)
		height = int(root.find('.//size/height').text)
		
		return boxes, width, height, categories
		
	# load the masks for an image
	"""Generate instance masks for an image.
	   Returns:
		masks: A bool array of shape [height, width, instance count] with
			one mask per instance.
		class_ids: a 1D array of class IDs of the instance masks.
	"""
	def load_mask(self, image_id):
		# get details of image
		info = self.image_info[image_id]
		
		# define anntation	file location
		path = info['annotation']
		
		# load XML
		boxes, w, h, categories = self.extract_boxes(path)
	   
		# create one array for all masks, each on a different channel
		masks = zeros([h, w, len(boxes)], dtype='uint8')
		
		# create masks
		class_ids = list()
		for i in range(len(boxes)):
			box = boxes[i]
			cat = categories[i]
			row_s, row_e = box[1], box[3]
			col_s, col_e = box[0], box[2]
			masks[row_s:row_e, col_s:col_e, i] = 1
			class_ids.append(self.class_names.index(cat))
		return masks, asarray(class_ids, dtype='int32')
	# load an image reference
	"""Return the path of the image."""
	def image_reference(self, image_id):
		info = self.image_info[image_id]
		print(info)
		return info['path']

config = FoodConfig()
config.display()


# prepare train set
train_set = FoodDataset()
train_set.load_dataset('.\\food_dataset', is_train=True)
train_set.prepare()
print('Train: %d' % len(train_set.image_ids))
# prepare test/val set
test_set = FoodDataset()
test_set.load_dataset('.\\food_dataset', is_train=False)
test_set.prepare()
print('Test: %d' % len(test_set.image_ids))



# Uncomment below to load and display random samples
'''image_ids = np.random.choice(train_set.image_ids, 10)
for image_id in image_ids:
    image = train_set.load_image(image_id)
    mask, class_ids = train_set.load_mask(image_id)
    visualize.display_top_masks(image, mask, class_ids, train_set.class_names)
'''

# Create model in training mode
model = modellib.MaskRCNN(mode="training", config=config, model_dir=MODEL_DIR)

# Which weights to start with?
init_with = "last"	#coco or last

if init_with == "coco":
	# Load weights trained on MS COCO, but skip layers that
	# are different due to the different number of classes
	model.load_weights(COCO_MODEL_PATH, by_name=True, exclude=["mrcnn_class_logits", "mrcnn_bbox_fc", "mrcnn_bbox", "mrcnn_mask"])
elif init_with == "last":
	# Load the last model trained and continue the training from that point
	model.load_weights(model.find_last(), by_name=True)
	
	
print("start training")	

model.train(train_set, test_set, 
			learning_rate=config.LEARNING_RATE, 
			epochs=10, 
			layers='heads')			
print("end training")

model_path = os.path.join(MODEL_DIR, "mask_rcnn_food.h5")
model.keras_model.save_weights(model_path)

