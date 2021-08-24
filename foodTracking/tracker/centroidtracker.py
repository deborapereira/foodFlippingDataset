# import packages
#\ from: https://www.pyimagesearch.com/

from scipy.spatial import distance as dist
from collections import OrderedDict
import numpy as np

# define constraints and rules to consider (or not) the identified object
MAX_NUMB_OBJS = 13
MIN_DIST_NEW_OBJS = 80
MAX_DIST_EXIST_OBJS = 30
MARKER_CATEGORY = 5
foodCategory=0

class CentroidTracker():
	def __init__(self, maxDisappeared=100):
		# initialize the next unique object ID along with two ordered
		# dictionaries used to keep track of mapping a given object
		# ID to its centroid and number of consecutive frames it has
		# been marked as "disappeared", respectively
		self.nextObjectID = 0
		self.objects = OrderedDict()
		self.objectsProp = OrderedDict()
		self.disappeared = OrderedDict()	
		self.removed_objs = OrderedDict()

		# store the number of maximum consecutive frames a given
		# object is allowed to be marked as "disappeared" until we
		# need to deregister the object from tracking
		self.maxDisappeared = maxDisappeared

	def register(self, centroid, centroidProp):
		# when registering an object we use the next available object
		# ID to store the centroid
		i=0
		notDel = True
		while i < len(self.removed_objs.keys()):
			removed_centroid = self.removed_objs[i][0]
			mydist = dist.euclidean(removed_centroid,centroid)
			print ("REGISTER dist with removed "+str(mydist))
			if mydist < 30:
				notDel=False
				objId= self.removed_objs[i][1]
				self.objects[objId] = centroid
				self.objectsProp[objId] = centroidProp
				self.disappeared[objId] = 0
				break
			i+=1
				
		if notDel:
			self.objects[self.nextObjectID] = centroid
			self.objectsProp[self.nextObjectID] = centroidProp
			self.disappeared[self.nextObjectID] = 0
			self.nextObjectID += 1

	def deregister(self, objectID):
		# to deregister an object ID we delete the object ID from
		# both of our respective dictionaries
		
		new_removed_idx = len(self.removed_objs.keys())
		removed_obj = np.array([self.objects[objectID], objectID])
		print(removed_obj)
		self.removed_objs[new_removed_idx] = removed_obj
		del self.objects[objectID]
		del self.objectsProp[objectID]
		del self.disappeared[objectID]

	def getStatus(self):
		return self.objects, self.objectsProp
		
	def update(self, rects):
		global foodCategory
		# check to see if the list of input bounding box rectangles
		# is empty
		if len(rects) == 0:
			# loop over any existing tracked objects and mark them
			# as disappeared
			for objectID in list(self.disappeared.keys()):
				self.disappeared[objectID] += 1

				# if we have reached a maximum number of consecutive
				# frames where a given object has been marked as
				# missing, deregister it
				if self.disappeared[objectID] > self.maxDisappeared:
					self.deregister(objectID)

			# return early as there are no centroids or tracking info
			# to update
			return self.objects, self.objectsProp

		# initialize an array of input centroids for the current frame
		inputCentroids = np.zeros((len(rects), 2), dtype="int")
		inputCentroidsProp = np.zeros((len(rects), 7), dtype="int")

		# loop over the bounding box rectangles
		for (i, (startX, startY, endX, endY, area,category, score)) in enumerate(rects):
			# use the bounding box coordinates to derive the centroid
			cX = int((startX + endX) / 2.0)
			cY = int((startY + endY) / 2.0)
			inputCentroids[i] = (cX, cY)
			inputCentroidsProp[i] = (area, category, startX, startY, endX, endY, score*100)
			
		# if we are currently not tracking any objects take the input
		# centroids and register each of them
		if len(self.objects) == 0:
			categories=np.zeros(6)
			print("Registering "+str(len(inputCentroids))+" objs")
			for i in range(0, len(inputCentroids)):
				objcat = inputCentroidsProp[i][1]
				categories[objcat] += 1
				self.register(inputCentroids[i], inputCentroidsProp[i])
			foodCategory = np.argmax(categories)
		# otherwise, we are currently tracking objects so we need to
		# try to match the input centroids to existing object
		# centroids
		else:
			# grab the set of object IDs and corresponding centroids
			objectIDs = list(self.objects.keys())
			objectCentroids = list(self.objects.values())
			objectCentroidsProps = list(self.objectsProp.values())

			# compute the distance between each pair of object
			# centroids and input centroids, respectively -- our
			# goal will be to match an input centroid to an existing
			# object centroid
			D = dist.cdist(np.array(objectCentroids), inputCentroids)

			# in order to perform this matching we must (1) find the
			# smallest value in each row and then (2) sort the row
			# indexes based on their minimum values so that the row
			# with the smallest value is at the *front* of the index
			# list
			rows = D.min(axis=1).argsort()

			# next, we perform a similar process on the columns by
			# finding the smallest value in each column and then
			# sorting using the previously computed row index list
			cols = D.argmin(axis=1)[rows]
			
			

			# in order to determine if we need to update, register,
			# or deregister an object we need to keep track of which
			# of the rows and column indexes we have already examined
			usedRows = set()
			usedCols = set()

			# loop over the combination of the (row, column) index
			# tuples
			for (row, col) in zip(rows, cols):
				# if we have already examined either the row or
				# column value before, ignore it
				# val
				if row in usedRows or col in usedCols:
					continue

				# otherwise, grab the object ID for the current row,
				# set its new centroid, and reset the disappeared
				# counter
				objectID = objectIDs[row]
				
				
				#check all distances, only one can be close to our target to be followed
				dist_new_obj = dist.cdist(np.array(objectCentroids), np.array([inputCentroids[col], inputCentroids[col]]))
				near_centroids = len(np.where(dist_new_obj < MAX_DIST_EXIST_OBJS)[0])/2
				
				#check distance between candidate and old centroid  
				mydist = dist.euclidean(self.objects[objectID],inputCentroids[col])
				
				if (near_centroids <2) and (mydist < 60) and (self.objectsProp[objectID][1] == inputCentroidsProp[col][1]): #same category, not confusion about distances
					self.objects[objectID] = inputCentroids[col]
					self.objectsProp[objectID] = inputCentroidsProp[col]
					self.disappeared[objectID] = 0

				# indicate that we have examined each of the row and
				# column indexes, respectively
				usedRows.add(row)
				usedCols.add(col)

			# compute both the row and column index we have NOT yet
			# examined
			unusedRows = set(range(0, D.shape[0])).difference(usedRows)
			unusedCols = set(range(0, D.shape[1])).difference(usedCols)

			# in the event that the number of object centroids is
			# equal or greater than the number of input centroids
			# we need to check and see if some of these objects have
			# potentially disappeared
			if D.shape[0] >= D.shape[1]:
				# loop over the unused row indexes
				for row in unusedRows:
					# grab the object ID for the corresponding row
					# index and increment the disappeared counter
					objectID = objectIDs[row]
					self.disappeared[objectID] += 1

					# check to see if the number of consecutive
					# frames the object has been marked "disappeared"
					# for warrants deregistering the object
					if self.disappeared[objectID] > self.maxDisappeared:
						self.deregister(objectID)

			# otherwise, if the number of input centroids is greater
			# than the number of existing object centroids we need to
			# register each new input centroid as a trackable object
			# if the rules of objs distance are respcted
			else:
				for col in unusedCols:
					
					dist_new_obj = dist.cdist(np.array(objectCentroids), np.array([inputCentroids[col], inputCentroids[col]]))

					if (len(self.objects) <MAX_NUMB_OBJS) and (np.all(dist_new_obj > MIN_DIST_NEW_OBJS)) and ((inputCentroidsProp[col][1] == foodCategory) or (inputCentroidsProp[col][1] == MARKER_CATEGORY)):
						self.register(inputCentroids[col],inputCentroidsProp[col])
				

		# return the set of trackable objects
		return self.objects, self.objectsProp 
