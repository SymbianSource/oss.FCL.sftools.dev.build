#============================================================================ 
#Name        : dryrun_parser.py 
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

""" parse a python file in a given environment, and get out some results """
import re
import os
import sys

if __name__ == '__main__':
    if len(sys.argv)<3:
        print("dryrun requires input txt file and output make file and the target to run")
        sys.exit(-1)

    #input arguments    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    make_target = sys.argv[3]
    
    
    variation_commands = {}
    regional_commands = []

    #parse imaker output
    fin = open(input_file, "r")
    imaker_pattern = '^imaker'
    foti_fota_pattern = ' fot[ia]'
    core_pattern = 'core|rofs3|flash$'
    workdir_pattern = 'WORKDIR='
    regional_pattern = '^unzip'
    regional_key = ""
    new_regional_key = ""
    regional_keys = []
    temporary_list = []
    unzip_commands = []
    workdir_string = ""
    
    for line in fin:
#       """ First look for unzip command. """
        if(re.search(regional_pattern, line)):
            temporary_list = line.split(' ')
            unzip_commands.append(line)
            new_regional_key = temporary_list[-1]
            #print regional_key
            if(not len(regional_key) == 0):
#                """ Will be processing next region, so store the commands for this region."""
                if(variation_commands.has_key(regional_key)):
                    variation_commands[regional_key] = regional_commands
                regional_key = new_regional_key
                if(variation_commands.has_key(new_regional_key)):
                    regional_commands = variation_commands[new_regional_key]
                else:
                    regional_commands = []
                    variation_commands[new_regional_key] = regional_commands
            else:
                variation_commands[new_regional_key] = regional_commands
                regional_key = new_regional_key
        if(re.search(imaker_pattern, line)):
            workdir_list = re.split(workdir_pattern, line)
            if(len(workdir_list) > 1):
                #print workdir_list
                workdir_string = re.split("\"", workdir_list[1])[0]
                #print "workdir_string"
                #print workdir_string
                if(not os.path.exists(workdir_string)):
                    os.makedirs(workdir_string)
            regional_commands.append(line)
    fin.close()
    variation_commands[regional_key] = regional_commands
    
#    """ Group the commands for the region and write the commands into a makefile."""
    fin = open(output_file, "w")
    all_string = "%s: foti_fota_all \\\n\tcore_rofs_image_all \\\n\trest_of_all" % make_target
    core_rofs_all_string = "core_rofs_image_all:"
    variation_image_all_string = "variation_all:"
    variation_image_string = ""
    core_rofs_string = ""
    core_image_id = 0
    e2flash_id = 0
    e2flash_all_string = "#pragma runlocal\ne2flash_target_all:\n"
    variation_image_id = 0
    variation_e2f_id = 0
    variation_id = 0
    
    foti_fota_all_string = "#pragma runlocal\nfoti_fota_all:"
    foti_fota_all_string += "\n\t"+unzip_commands[variation_id]
    rest_of_all_target_string = "rest_of_all:"
    rest_of_target_string = ""
    rest_of_target_id = 0

    count = 0
    dict_list = variation_commands.keys()
    for key in dict_list:
        print "before reverse key"
        print key
        print len(variation_commands.get(key))
    
    dict_list.reverse()

    for key in dict_list:
        print "key"
        print key
        print len(variation_commands.get(key))
    #    for command in commands:
    #        print command

    unzip_var_string = ""
    variation_image_all_string = ""
    variation_dependency = "variation0"
    for key in dict_list:
        commands = variation_commands.get(key)
        if(variation_id != 0):
            unzip_var_string += "unzip_var%d:%s" % (variation_id, variation_dependency)
            variation_dependency ="variation%d " % (variation_id)
            unzip_var_string += "\n\t"+unzip_commands[variation_id]
        all_string += "\\\n\tvariation%d " % variation_id
        variation_image_all_string +="variation%d: " % variation_id
        #print "no. of comands"
        #print len(commands)
        for command in commands:
            #print variation_id
            #print command
            if(re.search(foti_fota_pattern, command)):
                #print "foti command"
                #print command
                foti_fota_all_string += "\t"+command
            elif(re.search('flash$',command)):
                #print "flash command"
                #print command
                core_rofs_string += ("core_rofs_image%d:foti_fota_all" % (core_image_id))
                temp_string = re.sub('flash$', 'core-image rofs2-image rofs3-image', command)
                core_rofs_string += "\n\t"+temp_string+"\n"
                temp_string = re.sub('flash$', 'core-e2flash rofs2-e2flash rofs3-e2flash', command)
                e2flash_all_string += "\t"+temp_string
                core_rofs_all_string += " \\\n\t core_rofs_image%d" % core_image_id
                core_image_id += 1
            elif(re.search('core$',command)):
                #print "core command"
                #print command
                core_rofs_string += ("core_rofs_image%d:foti_fota_all" % (core_image_id))
                temp_string = re.sub('core$', 'core-image', command)
                core_rofs_string += "\n\t"+temp_string + "\n"
                temp_string = re.sub('core$', 'core-e2flash', command)
                e2flash_all_string += "\t"+temp_string
                core_rofs_all_string += " \\\n\t core_rofs_image%d" % core_image_id
                core_image_id += 1
            elif(re.search('rofs3$', command)):
                #print "rofs3 command"
                #print command
                core_rofs_string += ("core_rofs_image%d:foti_fota_all" % (core_image_id))
                temp_string = re.sub('rofs3$', 'rofs3-image', command)
                core_rofs_string += "\n\t"+temp_string + "\n"
                temp_string = re.sub('rofs3$', 'rofs3-e2flash', command)
                e2flash_all_string += "\t"+temp_string
                core_rofs_all_string += " \\\n\t core_rofs_image%d" % core_image_id
                core_image_id += 1
            elif(re.search('rofs2$',command)):
                #print "rofs2 command"
                #print variation_id
                #print command
                if(variation_id == 0):
                    variation_image_string += ("variation_image%d:rest_of_all")  %(variation_image_id)
                else:
                    variation_image_string += ("variation_image%d:unzip_var%d")  %(variation_image_id, variation_id)
                temp_string = re.sub('rofs2$', 'rofs2-image', command)
                variation_image_string += "\n\t"+temp_string+"\n"
                temp_string = re.sub('rofs2$', 'rofs2-e2flash', command)
                e2flash_all_string += "\t"+temp_string
                variation_image_all_string += " \\\n\tvariation_image%d" % variation_image_id
                variation_image_id += 1
            else:
                rest_of_target_string += ("\nrest_%d:core_rofs_image_all" % (rest_of_target_id))
                rest_of_target_string += "\n\t"+command+"\n"
                rest_of_all_target_string += " \\\n\t rest_%d" % rest_of_target_id
                rest_of_target_id += 1
        variation_id += 1
        unzip_var_string += "\n\n"
        variation_image_all_string += "\n\n"

    all_string += "\\\n\te2flash_target_all\n\n"
    #print core_rofs_all_string
    core_rofs_all_string += "\n\n"
    rest_of_all_target_string += "\n\n"
    e2flash_all_string += "\n\n"
    foti_fota_all_string += "\n\n"
    core_rofs_string += "\n\n"
    rest_of_target_string += "\n\n"
    unzip_var_string += "\n\n"
    variation_image_all_string += "\n\n"
    e2flash_all_string += "\n\n"
    fin.write(all_string)
    fin.write(core_rofs_all_string)
    fin.write(rest_of_all_target_string)
    fin.write(unzip_var_string)
    fin.write(variation_image_all_string)
    fin.write(foti_fota_all_string)
    fin.write(core_rofs_string)
    fin.write(variation_image_string)
    fin.write(rest_of_target_string)
    fin.write(e2flash_all_string)
    fin.close()