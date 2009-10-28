#============================================================================ 
#Name        : tools.py 
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

""" Archiving operations. """
import os
import logging
import buildtools
import codecs

_logger = logging.getLogger('archive')
#_logger.addHandler(logging.FileHandler('archive.log'))
#logging.basicConfig(level=logging.DEBUG)
logging.basicConfig()

class Tool(object):
    """ Tool abstract class. """
    def extension(self):
        """ This method should return the extension of the generated file. """
        raise NotImplementedError()

    def create_command(self, path, filename, manifests=None):
        """ This method should return an array of buildtools.Command.
            That list will get use to generate a build file (e.g make, ant).
            The list of command should support in parallel calling.
        """
        raise NotImplementedError()


class SevenZipArchiver(Tool):
    """ Creates task definitions for executing 7zip archive operations."""

    def __init__(self):
        Tool.__init__(self)

    def extension(self):
        """ Always return '.zip'. """
        return '.zip'

    def create_command(self, path, name, manifests=None):
        """ Returns a list of one command that will use 7za to archive the content."""
        cmd = buildtools.Command('7za', path)
        cmd.addArg('a')
        cmd.addArg('-tzip')
        # Include all in the current directory by default, assuming that
        # an include file or specific includes will be given
        cmd.addArg(name + self.extension())
        for manifest in manifests:
            cmd.addArg('@' + os.path.normpath(manifest))
        return [cmd]


class ZipArchiver(Tool):
    """ Creates task definitions for executing zip archive operations."""

    def __init__(self):
        Tool.__init__(self)

    def extension(self):
        """ Always return '.zip'. """
        return '.zip'

    def create_command(self, path, name, manifests=None):
        """ Returns a list of one command that will use zip to archive the content."""
        cmd = buildtools.Command('zip', path)
        cmd.addArg('-R')
        cmd.addArg(name + self.extension())
        # Include all in the current directory by default, assuming that
        # an include file or specific includes will be given
        cmd.addArg('.')
        for manifest in manifests:
            cmd.addArg('-i@' + os.path.normpath(manifest))
        return [cmd]


class Remover(Tool):
    """ Creates task definitions for executing zip archive operations."""
    def __init__(self):
        Tool.__init__(self)

    def extension(self):
        """ Always return '' """
        return ''

    def create_command(self, dummy_path, dummy_filename, manifests=None):
        """ Returns a list of one command that will use zip to archive the content."""
        cmds = []
        for manifest in manifests:
            file_input = codecs.open(manifest, 'r', "utf-8" )
            for line in file_input.readlines():
                if line.strip() != "":
                    cmds.append(buildtools.Delete(filename=line.strip()))
            file_input.close()
        return cmds
        

def get_tool(name):
    """ Return a tool using its id name. """
    constructor = TOOL_CONSTRUCTORS[name]
    return constructor()


TOOL_CONSTRUCTORS = {'zip': ZipArchiver,
                      '7za': SevenZipArchiver,
                      'remover': Remover}
