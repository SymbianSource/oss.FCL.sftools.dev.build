#============================================================================ 
#Name        : templatebuilder.py 
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

""" The template builder. """
import logging

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('integration.templatebuilder')

class TemplateBuilder:
    """ This class implements a template builder.
    """
    
    def __init__(self, config, product):
        self._config = config
        self._product = product
        
    def build(self):
        """ Render all the templates for the current product. """
        for config in self._config.getConfigurations(self._product, 'TemplateBuilder'):
            self._build_config(config)

    def __read_template(self, config):
        """ Read the whole file content.
        """
        logger.info("Using template '%s'..." % config['template.file'])
        ftr = open(config['template.file'], "r")
        content = ftr.read()
        ftr.close()
        return content

            
    def _build_config(self, config):
        """ Open config and render the template. """
        if config.name != None:
            logger.info("Building config '%s'..." % config.name)
        logger.info("Creating file '%s'..." % config['output.file'])
        output = open(config['output.file'], 'w+')        
        output.write(config.interpolate(self.__read_template(config)))
        output.close()
        