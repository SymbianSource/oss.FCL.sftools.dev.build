#============================================================================ 
#Name        : history.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

""" History file management related functionalities. """

import os


class HistoryFileManager:
    """ To manage EC history files. """
    
    weak_num = ""
    branch_name = ""
    file_dict = {}

    def __init__(self, arg1, arg2, arg3):
        """ Constructor. """
        self.path = str(arg1)
        self.weak_num = str(arg2)
        self.branch_name = str(arg3)

    def findActualFilePath(self):
        """Find the new path where the history file will be updated based on the week number and branch.
        
        This will normally the same path as used to copy from net drive to local drive.
        But for new branch / week number, the path will be different. """
        branch_dir_list = self.branch_name.split(".")
        for dir_ in branch_dir_list:
            self.path = os.path.join(self.path, dir_)
        if(self.path.endswith("\\0")):
            self.path = self.path[0:-2]
        return str(self.path)
        
    def findHistoryFilePath(self):
        """ Finds the path of the history file based on input
        branch and week number. """
        branch_dir_list = self.branch_name.split(".")
        for dir_ in branch_dir_list:
            if(not os.path.exists(os.path.join(self.path, dir_))):
                break
            else:
                self.path = os.path.join(self.path, dir_)
        if(self.path.endswith("\\0")):
            self.path = self.path[0:-2]

    def findFile(self):
        """ Finds the closest history file match to week number. """
        ret_file_name = None
        file_names = os.listdir(self.path)
        file_names_alone = file_names[:]

        # Find the history files without sub directory
        for name in file_names:
            if(os.path.isdir(os.path.join(self.path, name))):
                file_names_alone.remove(name)

        if(len(file_names_alone) > 0):
            file_names_alone.sort()
            low_index = 0
            high_index = len(file_names_alone) - 1

            if(high_index == 0):
                temp_name = file_names_alone[low_index]
                if(self.weak_num >= temp_name[0:4]):
                    return temp_name
                else:
                    return ret_file_name

            # Find the matching history file using binary search
            while(low_index < high_index):
                mid_index = (low_index + high_index) / 2
                temp_name = file_names_alone[mid_index]
                if(temp_name[0:4] < self.weak_num):
                    low_index = mid_index + 1
                else:
                    high_index = mid_index
                    
                temp_name = file_names_alone[high_index]
            if( self.weak_num >= temp_name[0:4]):
                ret_file_name = file_names_alone[high_index]
            else:
                if(high_index != 0):
                    ret_file_name = file_names_alone[high_index - 1]

        return str(ret_file_name)

