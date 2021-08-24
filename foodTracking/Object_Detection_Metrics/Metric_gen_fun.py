###########################################################################################
#                                                                                         #
# This sample shows how to evaluate object detections applying the following metrics:     #
#  * Precision x Recall curve       ---->       used by VOC PASCAL 2012)                  #
#  * Average Precision (AP)         ---->       used by VOC PASCAL 2012)                  #
#                                                                                         #
# Developed by: Rafael Padilla (rafael.padilla@smt.ufrj.br)                               #
#        SMT - Signal Multimedia and Telecommunications Lab                               #
#        COPPE - Universidade Federal do Rio de Janeiro                                   #
#        Last modification: Oct 9th 2018                                                 #
###########################################################################################

import argparse
import glob
import os
import shutil
# from argparse import RawTextHelpFormatter
import sys

from BoundingBox import BoundingBox
from BoundingBoxes import BoundingBoxes
from Evaluator import *
from utils import BBFormat
from statistics import mean

# Validate formats
def ValidateFormats(argFormat, argName, errors):
    if argFormat == 'xywh':
        return BBFormat.XYWH
    elif argFormat == 'xyrb':
        return BBFormat.XYX2Y2
    elif argFormat is None:
        return BBFormat.XYWH  # default when nothing is passed
    else:
        errors.append(
            'argument %s: invalid value. It must be either \'xywh\' or \'xyrb\'' % argName)


# Validate mandatory args
def ValidateMandatoryArgs(arg, argName, errors):
    if arg is None:
        errors.append('argument %s: required argument' % argName)
    else:
        return True


def ValidateImageSize(arg, argName, argInformed, errors):
    errorMsg = 'argument %s: required argument if %s is relative' % (argName, argInformed)
    ret = None
    if arg is None:
        errors.append(errorMsg)
    else:
        arg = arg.replace('(', '').replace(')', '')
        args = arg.split(',')
        if len(args) != 2:
            errors.append(
                '%s. It must be in the format \'width,height\' (e.g. \'600,400\')' % errorMsg)
        else:
            if not args[0].isdigit() or not args[1].isdigit():
                errors.append(
                    '%s. It must be in INdiaTEGER the format \'width,height\' (e.g. \'600,400\')' %
                    errorMsg)
            else:
                ret = (int(args[0]), int(args[1]))
    return ret


# Validate coordinate types
def ValidateCoordinatesTypes(arg, argName, errors):
    if arg == 'abs':
        return CoordinatesType.Absolute
    elif arg == 'rel':
        return CoordinatesType.Relative
    elif arg is None:
        return CoordinatesType.Absolute  # default when nothing is passed
    errors.append('argument %s: invalid value. It must be either \'rel\' or \'abs\'' % argName)


def ValidatePaths(arg, nameArg, errors):
    if arg is None:
        errors.append('argument %s: invalid directory' % nameArg)
    elif os.path.isdir(arg) is False and os.path.isdir(os.path.join(currentPath, arg)) is False:
        errors.append('argument %s: directory does not exist \'%s\'' % (nameArg, arg))
    # elif os.path.isdir(os.path.join(currentPath, arg)) is True:
    #     arg = os.path.join(currentPath, arg)
    else:
        arg = os.path.join(currentPath, arg)
    return arg


def getBoundingBoxes(directory,
                     isGT,
                     bbFormat,
                     coordType,
                     allBoundingBoxes=None,
                     allClasses=None,
                     imgSize=(0, 0)):
    """Read txt files containing bounding boxes (ground truth and detections)."""
    if allBoundingBoxes is None:
        allBoundingBoxes = BoundingBoxes()
    if allClasses is None:
        allClasses = []
    # # Read ground truths
    os.chdir(directory)
    files = glob.glob("*.txt")
    files.sort()

    # files = glob.glob(directory + "/*.txt")
    # files.sort()

    # Read GT detections from txt file
    # Each line of the files in the groundtruths folder represents a ground truth bounding box
    # (bounding boxes that a detector should detect)
    # Each value of each line is  "class_id, x, y, width, height" respectively
    # Class_id represents the class of the bounding box
    # x, y represents the most top-left coordinates of the bounding box
    # x2, y2 represents the most bottom-right coordinates of the bounding box
    for f in files:
        nameOfImage = f.replace(".txt", "")
        fh1 = open(f, "r")
        for line in fh1:
            line = line.replace("\n", "")
            if line.replace(' ', '') == '':
                continue
            splitLine = line.split(" ")
            if isGT:
                # idClass = int(splitLine[0]) #class
                idClass = (splitLine[0])  # class
                x = float(splitLine[1])
                y = float(splitLine[2])
                w = float(splitLine[3])
                h = float(splitLine[4])
                bb = BoundingBox(
                    nameOfImage,
                    idClass,
                    x,
                    y,
                    w,
                    h,
                    coordType,
                    imgSize,
                    BBType.GroundTruth,
                    format=bbFormat)
            else:
                # idClass = int(splitLine[0]) #class
                idClass = (splitLine[0])  # class
                confidence = float(splitLine[1])
                x = float(splitLine[2])
                y = float(splitLine[3])
                w = float(splitLine[4])
                h = float(splitLine[5])
                bb = BoundingBox(
                    nameOfImage,
                    idClass,
                    x,
                    y,
                    w,
                    h,
                    coordType,
                    imgSize,
                    BBType.Detected,
                    confidence,
                    format=bbFormat)
            allBoundingBoxes.addBoundingBox(bb)
            if idClass not in allClasses:
                allClasses.append(idClass)
        fh1.close()
    return allBoundingBoxes, allClasses

def back_org_dir(prev_dir):
    back_dirs = len(prev_dir.split("/"))
    change_dir = ""
    for _ in range(back_dirs):
        change_dir += "../"
    # Get detected boxes
    os.chdir(change_dir)

def extract_metrics_custom(gtFolder , detFolder , gtFormat , detFormat, iouThreshold, gtCoordType, detCoordType, imgSize):
    # Get groundtruth boxes
    allBoundingBoxes, allClasses = getBoundingBoxes(
        gtFolder, True, gtFormat, gtCoordType, imgSize=imgSize)

    back_org_dir(gtFolder)

    allBoundingBoxes, allClasses = getBoundingBoxes(
        detFolder, False, detFormat, detCoordType, allBoundingBoxes, allClasses, imgSize=imgSize)

    back_org_dir(detFolder)

    allClasses.sort()

    evaluator = Evaluator()
    acc_AP = 0
    validClasses = 0

    results = evaluator.GetPascalVOCMetrics(allBoundingBoxes , IOUThreshold=iouThreshold)

    all_cl_TP = 0 ## True positivies taking into account all the classes
    all_cl_FP = 0 ## False positivies taking into account all the classes
    all_cl_FN = 0 ## False negativies taking into account all the classes
    all_cl_GroundPosi = 0 ## Ground truth total positive cases in all classes
    # each detection is a class
    f1_all = []
    prec_all = []
    rec_all = []

    per_class_metrics = {}
    for metricsPerClass in results:

        # Get metric values per each class
        cl = metricsPerClass['class']
        ap = metricsPerClass['AP']
        precision = metricsPerClass['precision']
        recall = metricsPerClass['recall']
        totalPositives = metricsPerClass['total positives']
        total_TP = metricsPerClass['total TP']
        total_FP = metricsPerClass['total FP']
        total_FN = totalPositives - total_TP #???
        f1 = metricsPerClass['single_F1']
        single_prec = metricsPerClass['single_precision']
        single_recal =  metricsPerClass['single_recal']    

        ## Build the new results dictionary to return in the end
        per_class_metrics[cl]={"AP": ap, "Precision": single_prec, "Recall":single_recal, "F1": f1 , "TP":total_TP, "FP":total_FP, "FN":total_FN}

        ## Append each class metrics to an array
        f1_all.append(f1)
        prec_all.append(single_prec)
        rec_all.append(single_recal)

        ## Sum the FP FN and TP to the all_class## Sum the FP FN and TP to the all_class
        all_cl_GroundPosi += totalPositives ## Ground truth total positive cases
        all_cl_TP += total_TP
        all_cl_FP += total_FP
        all_cl_FN += total_FN

        if totalPositives > 0:
            validClasses = validClasses + 1
            acc_AP = acc_AP + ap
            prec = ['%.2f' % p for p in precision]
            rec = ['%.2f' % r for r in recall]
            ap_str = "{0:.2f}%".format(ap * 100)
        
    ## Calculate the Precision, Recal and F1 taking into account all the classes
    # all_cl_prec = all_cl_TP / (all_cl_TP + all_cl_FP)
    # all_cl_recal = all_cl_TP / all_cl_GroundPosi
    # all_cl_f1 = 2*(all_cl_prec*all_cl_recal) / (all_cl_prec + all_cl_recal)
    all_cl_f1   = mean(f1_all)
    all_cl_prec = mean(prec_all)
    all_cl_recal= mean(rec_all)
    mAP = acc_AP / validClasses
    
    all_metrics = {"mAP": mAP, "Average_Precision": all_cl_prec, "Average_Recall": all_cl_recal, "Average_F1": all_cl_f1}

    return all_metrics, per_class_metrics


# if __name__ == "__main__":
#     # Arguments validation
#     # Validate formats
#     gtFormat = "xyrb" #ValidateFormats(args.gtFormat, '-gtformat', errors)
#     detFormat = "xyrb" #ValidateFormats(args.detFormat, '-detformat', errors)
#     # Groundtruth folder
#     gtFolder = "../groundtruths"
#     detFolder = "../detections_tf"
#     imgSize = (0, 0)
#     gtCoordType = CoordinatesType.Absolute
#     detCoordType = CoordinatesType.Absolute
#     iouThreshold = 0.5

#     print(extract_metrics_custom(gtFolder , detFolder , gtFormat , detFormat, iouThreshold, gtCoordType, detCoordType, imgSize))