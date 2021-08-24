# USAGE
# python food_tracker.py 

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
from mrcnn.config import Config
from mrcnn import utils
import mrcnn.model as modellib
from mrcnn import visualize
from mrcnn.model import log
from xml.etree import ElementTree
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
from keras.preprocessing.image import load_img
from keras.preprocessing.image import img_to_array
import tensorflow as tf
from tracker.centroidtracker import CentroidTracker


# define th directory of the videos 
video_dir= 'D:\\videos\\'


# Root directory of the project
ROOT_DIR = os.path.abspath("../")
# Directory to save logs and trained model
MODEL_DIR = os.path.join(ROOT_DIR, "logs")
# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library

#GPU configuration
config = tf.ConfigProto()
config.gpu_options.allow_growth = False
config.gpu_options.per_process_gpu_memory_fraction = 0.7
sess = tf.Session(config=config)

#number of images to process in each batch (depends on GPU memory capabilities)
batch_size = 1

# NN configuration
class FoodConfig(Config):
	# Give the configuration a recognizable name
	NAME = "food"
	NUM_CLASSES = 1 + 5	 # background, hamburger, chicken, zucchini, eggplant, marker
	DETECTION_MIN_CONFIDENCE = 0.92
	IMAGES_PER_GPU = batch_size
	RPN_ANCHOR_SCALES = (32,64) 

config = FoodConfig()


#Loading the model in the inference mode
model = modellib.MaskRCNN(mode="inference", config=config, model_dir=MODEL_DIR)
# loading the trained weights o the custom dataset
model_path = model.find_last()
model.load_weights(model_path, by_name=True)



# fast forward, set ffset > 0 to skip "ffset" frames each cicle
ffset = 0 
# determine foreground pixel sum threshold to skip static frames
foreground_thr = 900000

#ROI limits
ROI_min_width=220
ROI_max_width=1100
ROI_min_height=50
ROI_max_height=600

for filename in os.listdir(video_dir):
		if filename.endswith(".mp4"):
		
			print(filename)
			#open video file
			cap = cv2.VideoCapture(video_dir+filename)
			
			# Default resolutions of the frame are obtained.The default resolutions are system dependent.
			# We convert the resolutions from float to integer.
			frame_width = int(cap.get(3))
			frame_height = int(cap.get(4))
			 
			# Define the codec and create VideoWriter object. The output is stored in 'filename.avi' file.
			out = cv2.VideoWriter(video_dir+'results\\'+filename+'.avi',cv2.VideoWriter_fourcc('M','J','P','G'), 90, (1280,720))
			
			# Create a log file for the video to save frame info:
			# for each object detected and tracked in each frame a row is added to the CSV file 
			# containing the following info: iteration,frame_number,object_ID,obj_category,obj_pos_x_center,obj_pos_y_center,obj_area,startX,startY,endX,endY, identification_score
			logfile = open(video_dir+'results\\'+filename+'.csv', 'w', newline='\n')
			headerStr = "iteration,frame_num,obj_ID,obj_cat,obj_pos_x,obj_pos_y,obj_area,startX,startY,endX,endY, score\n"
			logfile.write(headerStr)
			
			frame_count=0
			# skip first 10 frames to avoid image artifacts due to camera initialization (e.g. light, autofocus)
			for i in range(0,10):
				ret,frame = cap.read()
				out.write(frame)
				frame_count += 1

			# Create a centroid traker object. Each object can be not identified for max 800 frames before deleting from the list 
			# This great number is due to the constant object occlusion during the task (e.g. subject's arms, spatula) 
			ct = CentroidTracker(800)
			
			# Create a foreground - background identifier to determine if the current frame is interesting or not
			# if it is almost only background the frame is not condisered for the tracking (skip static/repeated frames) to save computation time 
			fgbg = cv2.createBackgroundSubtractorKNN(history = 300, detectShadows=True)	
			
			# initialize counters
			marker_id = -1
			i = 0
			last_analyzed_frame = frame

			# for each frame of the video
			while True:
				images = []
				frames = []
				i+=1
				#log current iteration				
				print("iteration ", i)
				j=0
				ff=0
				while (j < batch_size):
				
					# read the next frame 
					ret,frame = cap.read()
					frame_count += 1
					if ret:	
						#extract the ROI of the video 
						frame[0:ROI_min_height,0:frame_width-1,:] = 0. 
						frame[ROI_max_height:frame_height-1,0:frame_width-1,:] = 0. 
						frame[0:frame_height-1,0:ROI_min_width,:] = 0.
						frame[0:frame_height-1,ROI_max_width:frame_width-1,:] = 0. 

						# calculate the foreground mask and sum all the foreground pixels
						fgmask = fgbg.apply(frame)
						fgsum = fgmask.sum()
						
						if fgsum > foreground_thr:
							#skip "ffset" frames if ffset>0
							if ff < ffset:
								#attach to the video the frame skipped 
								out.write(frame)
								ff +=1
							else:
								ff=0
								j+=1
								# convert frame in RGB space
								img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
								frames.append(frame)
								img = img_to_array(img)
								images.append(img)
						else:
							# retrive the current objects tracked 
							objects, objectsProp = ct.getStatus()

							# draw the objects already tracked on the current frame
							for (objectID, centroid) in objects.items():
								# draw the centroid point, the obj ID, the category confidence(white) and the mask area with the color dependent on the class ID
								text = str(objectID)
								cv2.putText(frame, text, (centroid[1] - 10, centroid[0] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
								cv2.putText(frame, str(objectsProp[objectID][6]), (centroid[1] + 10, centroid[0] + 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
								cv2.circle(frame, (centroid[1], centroid[0]), 2, (0, 0, 255), -1)
								class_id = objectsProp[objectID][1]	
								if class_id == 1:
									color_bbox =  (0, 0, 255)
								elif class_id == 2:
									color_bbox =  (0, 255, 255)
								elif class_id == 3:
									color_bbox =  (0, 255, 0)
								elif class_id == 4:
									color_bbox =  (255, 0, 255)
								else:
									color_bbox =  (255, 255, 255)
								cv2.rectangle(frame, (objectsProp[objectID][3],objectsProp[objectID][2]), (objectsProp[objectID][5],objectsProp[objectID][4]),color_bbox, 1)
							# add the current frame to the output stream
							out.write(frame)
					else:
						break
				
				if not ret:
					break
				else:
					# run the detection algorithm on the batch (batch_size images)
					result= model.detect(images)
					
					#for each image of the batch
					for j in range(0,batch_size):
						r = result[j]
						#extract boxes, masks, classes and scores 
						boxes = r['rois']
						masks = r['masks']
						classes = r['class_ids']
						scores = r['scores']
	
						#boxes output of the NN are not used, bounding box and centroid of the masks are calculated instead (more reliable)

						#calculate centroid of the masks
						img_mask =  np.sum(masks,2)    
						myobjs=[]	
						for mask in range(masks.shape[2]):
							curr_mask = masks[:,:,mask]
							mask_true = np.where(curr_mask == True)  
							x = int(np.average(mask_true[0]))   
							y = int(np.average(mask_true[1])) 
							img_mask[x,y] = 2
							mask_area = len(mask_true[0])
							# a yellow circle is drawn for each object identified in the frame
							cv2.circle(frames[j], ( y, x), 4, (0, 255, 255), -1)
							myobjs.append([int(np.min(mask_true[0])),int(np.min(mask_true[1])), int(np.max(mask_true[0])),int(np.max(mask_true[1])), mask_area, classes[mask],  scores[mask]])
							
						# centroid tracker is updated with the object list identified in this frame
						objects, objectsProp = ct.update(np.array(myobjs))

						# loop over the tracked objects
						for (objectID, centroid) in objects.items():
							# draw the centroid point, the obj ID, the category confidence(white) and the mask area with the color dependent on the class ID
							text = str(objectID)
							cv2.putText(frames[j], text, (centroid[1] - 10, centroid[0] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
							cv2.putText(frames[j], str(objectsProp[objectID][6]), (centroid[1] + 10, centroid[0] + 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
							cv2.circle(frames[j], (centroid[1], centroid[0]), 2, (0, 0, 255), -1)
							class_id = objectsProp[objectID][1]	
							if class_id == 1:
								color_bbox =  (0, 0, 255)
							elif class_id == 2:
								color_bbox =  (0, 255, 255)
							elif class_id == 3:
								color_bbox =  (0, 255, 0)
							elif class_id == 4:
								color_bbox =  (255, 0, 255)
							else:
								color_bbox =  (255, 255, 255)
							cv2.rectangle(frames[j], (objectsProp[objectID][3],objectsProp[objectID][2]), (objectsProp[objectID][5],objectsProp[objectID][4]),color_bbox, 1)
							
							# log row for current object in the CSV file
							logStr = str((batch_size*(i-1))+j)+","+str(frame_count-batch_size+j)+","+text+","+str(objectsProp[objectID][1])+","+str(centroid[0])+","+str(centroid[1])+","+str(objectsProp[objectID][0])+","+str(objectsProp[objectID][2])+","+str(objectsProp[objectID][3])+","+str(objectsProp[objectID][4])+","+str(objectsProp[objectID][5])+","+str(objectsProp[objectID][6])+"\n"
							logfile.write(logStr)
							
						#show the result to the user	
						cv2.imshow('image',frames[j])
						# add the current frame to the output stream
						out.write(frames[j])
					
					k = cv2.waitKey(60) & 0xff
					if k == 27:
						break

			cap.release()
			out.release()					
