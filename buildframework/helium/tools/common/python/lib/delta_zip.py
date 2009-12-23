#============================================================================ 
#Name        : delta_zip.py 
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

import os
import shutil
import re
import fileutils
import buildtools
import logging

_logger = logging.getLogger('delta_zip')
logging.basicConfig(level=logging.INFO)

class MD5SignatureBuilder(object):
    """ MD5 CRC creation base class"""
    def __init__(self, build_area_root, nb_split, temp_dir, exclude_dirs, list_of_files):
        """constructor"""
        if not build_area_root.endswith(os.sep):
            self.build_area_root = build_area_root + os.sep
        self.nb_split = int(nb_split)
        self.temp_dir = temp_dir
        self.exclude_dirs = exclude_dirs
        self.list_of_files = list_of_files
        
    def create_file_list(self):
        """Create list of files (was list_files.pl)"""
        #list_of_files_symbol = os.path.join(self.temp_dir, "list_files_sym.txt")
        
        if not os.path.exists(self.temp_dir):
            os.mkdir(self.temp_dir)
      
        fp_filelist = open(self.list_of_files, 'w')
        #fp_filelist_sym = open(list_of_files_symbol, 'w')
                        
        scanner = fileutils.FileScanner(self.build_area_root)
        scanner.add_include('**')
        
        for _dir in self.exclude_dirs.split(','):
            _dir = _dir.replace(self.build_area_root, "")
            scanner.add_exclude(_dir)

        for path in scanner.scan():
            if (not os.path.isdir(path)) or (os.path.isdir(path) and (os.listdir(path) != []  and os.listdir(path) != ['.svn'])):
                (drive, _) = os.path.splitdrive(path)
                path = path.replace(drive + os.sep, "")
                fp_filelist.write(path + "\n")
            
    def split_file_list(self):
        """Split the list of files for parallelalisation"""
        md5_dir = os.path.join(self.temp_dir, "md5_temp")
        self.dest_dir = os.path.join(md5_dir, str(self.nb_split))
        if not os.path.exists(self.dest_dir):
            os.makedirs(self.dest_dir)
        fp_split = []
        #Open files
        #White list_of_lists.txt
        self.list_of_lists = self.dest_dir + "/list_of_lists.txt"
        fp_list_of_lists = open(self.list_of_lists, 'w')
        for i in range(self.nb_split):
            filename = self.dest_dir + "/" + str(i) + ".txt"
            _fp = open(filename, 'w')
            fp_split.append(_fp)
            #Write in list_of_lists
            fp_list_of_lists.write(filename + "\n")
            
        #Write in files
        fp_read = open(self.list_of_files, 'r') 
        line = fp_read.readline()
        line_number = 0
        while(line != ""):
            fp_split[line_number % len(fp_split)].write(line)
            line = fp_read.readline()
            line_number += 1
        
        fp_list_of_lists.close()    
        fp_read.close()
        for _fp in fp_split:
            _fp.close()
            
    def create_command_list(self):        
        """ create the command to run evalid on each file in the list of files"""
        liste = buildtools.CommandList()
        
        #tools_dir = os.path.join(self.build_area_root, "/epoc32/tools")
        
        for i in range(self.nb_split):
            #liste.addCommand(buildtools.Command("perl -I"+tools_dir, tools_dir, [os.path.join(tools_dir,"evalid_multiple.pl"), "-f", self.__get_partial_input_file_name(i), "> "+self.__get_partial_signature_file_name(i) ]))
            liste.addCommand(buildtools.Command("evalid", os.sep, ["", "-f", self.__get_partial_input_file_name(i) + " "+self.build_area_root, self.__get_partial_signature_file_name(i) ]))
            
        return liste
    
    def __get_partial_input_file_name(self, _nb):
        """ get the input file name string as has been created so far and add .txt to it"""
        return os.path.join(self.dest_dir, str(_nb) + ".txt")
            
    def __get_partial_signature_file_name(self, _nb):
        """ get the signature file name string as has been created so far and add .md5 to it"""
        return os.path.join(self.dest_dir, str(_nb) + ".md5")
        
    def concatenate_signature_files(self, signature_file):
        """ concatenate all the files with the MD5 CRC in """
        # Get header
        _fp = open(self.__get_partial_signature_file_name(0), 'r')
        line = ""
        header_temp = ""
        header = ""
        while (re.search(r'(\S+).*MD5=(\S+)', line) == None):
            header_temp = header_temp + line
            line = _fp.readline()
        
        for line in header_temp.splitlines():
            if re.match(r'Directory:.*', line):
                line =  "Directory:" + self.build_area_root
            if re.match(r'FileList:.*', line):
                line = "FileList:" + self.list_of_files
            header = header + line + "\n"
        
        #re.sub(r'(Directory:).*\n', "\1"+self.build_area_root, header)
        #re.sub(r'(FileList:).*\n', "\1"+self.list_of_files, header)
            
        header_size = len(header.splitlines())
        
        fp_md5_signatures_file = open(signature_file, 'w')
        fp_md5_signatures_file.write(header)
        for i in range(self.nb_split):
            _fp = open(self.__get_partial_signature_file_name(i), 'r')

            for i in range(header_size): # Skip header
                _fp.readline()
            
            fp_md5_signatures_file.write(_fp.read())
            _fp.close()
        fp_md5_signatures_file.close()

    def write_build_file(self):
        """ create the file of the list of files to have a CRC created"""
        self.create_file_list()
        self.split_file_list()
        self.create_build_file()
    
    def create_build_file(self):
        """ there should always be an overloaded version of this method in sub-classes"""
        raise NotImplementedError()
    
    def build(self, signature_file):
        """create the list of files generate the MD5 CRC and create the final file with CRCs in"""
        self.write_build_file()
        self.compute_evalid_MD5()
        self.concatenate_signature_files(signature_file)
            
    def compute_evalid_MD5(self):
        """ there should always be an overlaoded version in the methos sub-class"""
        raise NotImplementedError()
    
class MD5SignatureBuilderEBS(MD5SignatureBuilder):
    """ build the MD5 CRCs for all the files in the list of files"""
    def create_build_file(self):
        """Create EBS XML"""
        liste = self.create_command_list()
        self.makefile = self.dest_dir + "/ebs.xml"
        buildtools.convert(liste, self.makefile, "ebs")

    def compute_evalid_MD5(self):
        """Compute MD5 using the requested parallel build system"""
        os.chdir(self.build_area_root)
        os.system("perl -I%HELIUM_HOME%/tools/common/packages %HELIUM_HOME%/tools/compile/buildjob.pl -d " + self.makefile + " -l " + os.path.join(self.dest_dir, "md5.log") + " -n " + str(int(os.environ['NUMBER_OF_PROCESSORS'])*2))

"""
Run the delta zipping over the EC build system
"""
class MD5SignatureBuilderEC(MD5SignatureBuilder):
    """ The MD5 CRC creation for delta zippinf for use on EC machines"""
    def __init__(self, build_area_root, nb_split, temp_dir, exclude_dirs, ec_cluster_manager, ec_build_class, list_of_files):
        MD5SignatureBuilder.__init__(self, build_area_root, nb_split, temp_dir, exclude_dirs, list_of_files)
        self.ec_cluster_manager = ec_cluster_manager
        self.ec_build_class = ec_build_class
    
    def create_build_file(self):
        """Create makefile"""
        liste = self.create_command_list()
        self.makefile = self.dest_dir + "/Makefile"
        buildtools.convert(liste, self.makefile, "make")

    def compute_evalid_MD5(self):
        """Compute MD5 using the requested parallel build system"""
        root_path = os.environ['EMAKE_ROOT'] +";" + "c:\\apps;"
        os.chdir(self.build_area_root)
        
        print "emake --emake-cm=" + self.ec_cluster_manager + " --emake-class=" + self.ec_build_class + " --emake-root="+root_path+ " --emake-emulation-table make=symbian,emake=symbian,nmake=nmake -f " + self.makefile
        os.system("emake --emake-cm=" + self.ec_cluster_manager + " --emake-annodetail=basic,history,file,waiting --emake-annofile="+self.temp_dir+"\\delta_zip_anno.xml"+ " --emake-class=" + self.ec_build_class + " --emake-root="+root_path+" --emake-emulation-table make=symbian,emake=symbian,nmake=nmake -f " + self.makefile)

class DeltaZipBuilder(object):
    """methods to create the delta zip after all the prep"""
    def __init__(self, build_area_root, temp_path, old_md5_signature, new_md5_signature):
        self.build_area_root = os.path.join(build_area_root, os.sep)
        self.temp_path = temp_path
        self.old_md5_signature = old_md5_signature
        self.new_md5_signature = new_md5_signature
        self.sign_dic = SignaturesDict()
        
    def __fill_signature_dict(self, signature_file, old_new):
        """ read each line of signature file search for .MD5"""
        _fp = open(signature_file, 'r')
        lines = _fp.read().splitlines()
        _fp.close()
        for line in lines:
            info = re.search(r'([ \S]+) TYPE=.*MD5=(\S+)', line)
            if info != None:
                filename = info.group(1)
                if not self.sign_dic.has_key(filename):
                    self.sign_dic[filename] = ["", ""]
                self.sign_dic[filename][old_new] = info.group(2)                
    
    def create_delta_zip(self, zip_file, delete_list_file, no_of_zips, ant_file):
        """Create Delta zip and list of file to delete."""
        
        no_of_zips = int(no_of_zips)
        self.__fill_signature_dict(self.old_md5_signature, 0)
        self.__fill_signature_dict(self.new_md5_signature, 1)
        
        #fp_dic = open(zip_file + ".dic.txt", 'w')
        #fp_dic.write(str(self.sign_dic))
        #fp_dic.close()
        
        delete_list = []
        
        if not os.path.exists(os.path.dirname(delete_list_file)):
            os.mkdir(os.path.dirname(delete_list_file))
        if not os.path.exists(self.temp_path):
            os.mkdir(self.temp_path)
        
        archive_txt = open(os.path.join(self.temp_path, 'create_zips.txt'), 'w')

        for _file in self.sign_dic.keys():
            filepath = os.path.join(self.build_area_root, _file)
            
            signatures = self.sign_dic[_file]
            
            ( _, rest) = os.path.splitdrive(filepath)
            (frontpath, rest) = os.path.split(rest)
            
            if (signatures[0] != signatures[1]):  #File changed between the 2 BAs
                if (signatures[0] != "") and  (signatures[1] != ""): # File is present in both BAs and has changed
                    if os.path.exists(filepath): # File could have been deleting after running 'build-md5':
                        archive_txt.write(_file + "\n")
                else:
                    if (signatures[1] != ""): # New file
                        if os.path.exists(filepath):
                            archive_txt.write(_file + "\n")
                    else: # Deleted file
                        delete_list.append(filepath)
        
        archive_txt.close()
        
        splitter = MD5SignatureBuilder('', no_of_zips, self.temp_path, '', os.path.join(self.temp_path, 'create_zips.txt'))
        splitter.split_file_list()
        
        os.chdir(self.build_area_root)
        
        (frontpath, rest) = os.path.split(zip_file)
        stages = buildtools.CommandList()
        
        for i in range(no_of_zips):
            md5_dir = os.path.join(self.temp_path, "md5_temp")
            path = os.path.join(md5_dir, os.path.join(str(no_of_zips), str(i) + '.txt'))
            output = os.path.join(frontpath, rest.replace(".zip", "_part_%sof%s.zip" % (str(i+1), str(no_of_zips))))
            
            cmd = buildtools.Command('7za.exe', self.build_area_root)
            cmd.addArg('a')
            # Set the format to be zip-compatible
            cmd.addArg('-tzip')
            cmd.addArg(output)
            cmd.addArg('@' + path)
            
            stages.addCommand(cmd)

        writer = buildtools.AntWriter(ant_file)
        writer.write(stages)

        fp_delete = open(delete_list_file, 'w')
        fp_delete.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        fp_delete.write("<updateinstructions>\n")
        for i in delete_list:
            fp_delete.write("<deletefileaction target=\"" + i[2:] + "\"/>\n")
        fp_delete.write("</updateinstructions>\n")
        fp_delete.close()
        
                
class SignaturesDict(dict):
    """ class to handle signature comparison"""
    def __init__(self):
        """ constructor"""
        dict.__init__(self)
    
    def __str__(self):
        """ compare the tree structures"""
        string = ""
        #o = OldNewBA()
        both = False
        only_old = False
        only_new = False
        for filename in self.keys():
            signatures = self[filename]
            if signatures[0] == signatures[1]: #File did not change
                both = True
            elif (signatures[0] != "") and  (signatures[1] != ""): # File is present in both BAs and has changed
                both = False
            else:
                if (signatures[1] != ""): # New file
                    only_old = True
                else: # Deleted file
                    only_new = True
            
            string = string + filename + " " + str(both) + " " + " " + str(only_old) + " " + str(only_new) + " " + self[filename][0] + " " + self[filename][1] + "\n"
        
        return string

def readEvalid(dir):
    filesdict = {}
    for root, _, files in os.walk(dir):
        for name in files:
            f = os.path.join(root, name)
            directory = None
            for md5line in open(f):
                if md5line.startswith('Directory:'):
                    directory = md5line.replace('Directory:', '').replace('\n', '')
                if 'MD5=' in md5line:
                    info = re.search(r'([ \S]+) TYPE=.*MD5=(\S+)', md5line)
                    if info != None:
                        assert directory
                        filesdict[os.path.join(directory, info.group(1))] = info.group(2)
    return filesdict
    
def changedFiles(atsevalidpre, atsevalidpost):
    filesbefore = readEvalid(atsevalidpre)
    filesafter = readEvalid(atsevalidpost)
    
    changedfiles = []
    
    for key in filesafter.keys():
        if key not in filesbefore:
            changedfiles.append(key)
        else:
            if filesafter[key] != filesbefore[key]:
                changedfiles.append(key)
    
    return changedfiles
    
def evalidAdomapping(builddrive, dest, adomappingfile):
    os.chdir(builddrive)
    i = 0
    if os.path.exists(dest):
        shutil.rmtree(dest)
    os.mkdir(dest)
    for line in open(adomappingfile):
        dir = line.split('=')[0].replace(r'\:', ':')
        tmpfile = os.path.join(dest, str(i))
        os.system('evalid -g ' + dir + ' ' + tmpfile)
        i = i + 1