#!/bin/bash

rsync -avzr --delete-excluded --progress --exclude='*jpg' --exclude='*ppt' --exclude='*txt' --exclude='*doc' --exclude='*mat' --exclude='*html' --exclude='*dat' --exclude='*db' --exclude='*DS_Store' "/Volumes/PubStore/_Production Data/MEMs PROBE DATA/OSF" /Users/jjangsangy/Desktop/Work/Pin\ Logs

rsync -avzr --delete-excluded --progress --exclude='*lnk' --exclude='*pptx' --exclude='*JPG' --exclude='*db' --exclude='\~\$*' "/Volumes/Optical Comp/Inventory/MEMS/" "/Users/jjangsangy/Desktop/Work/MEMS/"
