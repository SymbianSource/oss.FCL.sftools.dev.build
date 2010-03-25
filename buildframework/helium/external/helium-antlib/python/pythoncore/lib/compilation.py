#============================================================================ 
#Name        : compilation.py 
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

""" Package contains compilation phase related modules """

import logging
import build.io
import sysdef.api
import sysdef.io

logging.basicConfig(level=logging.INFO)

class BinarySizeLogger(object):
    """ Read Binary size from rom output logs """
    def __init__(self, sysDef):
        self.sysDef = sysDef
        
    def read_output_binaries_per_unit(self, build_logs):
        # Read in the output binaries of each unit
        logging.info('Reading the output binaries created by each unit.')
        if len(build_logs) == 0:
            raise Exception('List of build logs is empty!')
        logging.info("The list of log files:\n")
        logging.info("\n".join(build_logs))
        for logpath in build_logs:
            binaries_reader = build.io.AbldLogWhatReader(logpath)
            self.sysDef.merge_binaries(binaries_reader)
        
    def read_binary_sizes_in_rom_output_logs(self, rom_logs):    
        # Read in the binary sizes listed in the ROM output logs
        logging.info('Reading the binary sizes of each binary from ROM logs.')
        if len(rom_logs) == 0:
            raise Exception('List of ROM logs is empty!')
        logging.info("The list of log files:\n")
        logging.info("\n".join(rom_logs))
        for log in rom_logs:
            binary_sizes_reader = build.io.RombuildLogBinarySizeReader(log)
            self.sysDef.merge_binary_sizes(binary_sizes_reader)
    
    def write2csvfile(self, binary_sizes_output_file, sysdef_config_list):
        # Write out a .csv file containing
        size_writer = sysdef.io.FlashImageSizeWriter(binary_sizes_output_file)
        size_writer.write(self.sysDef, sysdef_config_list)
        size_writer.close()