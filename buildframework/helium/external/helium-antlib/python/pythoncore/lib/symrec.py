#============================================================================ 
#Name        : symrec.py 
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

""" SYMREC metadata file generation. """
import xml.dom.minidom
import codecs
import os
import re
import logging
import fileutils
import csv

LOGGER = logging.getLogger("symrec")
logging.basicConfig(level=logging.INFO)

def _cleanup_list(input):
    result = []
    for chars in input:
        if chars is not None and chars.strip() != "":
            result.append(chars)
    return result

def xml_setattr(node, attr, value):
    """ Create the attribute if needed. """
    node.setAttribute(attr, value)

def is_child_text_only(node):
    """ Returns true if child node are all from TEXT_NODE type. """
    for child in node.childNodes:
        if child.nodeType != xml.dom.minidom.Node.TEXT_NODE:
            return False
    return True


def ignore_whitespace_writexml(self, writer, indent="", addindent="", newl=""):
    """ This version of writexml will ignore whitespace text to alway render
    the output in a structure way.
    indent = current indentation
    addindent = indentation to add to higher levels
    newl = newline string
    """
    writer.write(indent + "<" + self.tagName)

    attrs = self._get_attributes()
    a_names = attrs.keys()
    a_names.sort()

    for a_name in a_names:
        writer.write(" %s=\"" % a_name)
        xml.dom.minidom._write_data(writer, attrs[a_name].value)
        writer.write("\"")
    if self.childNodes:
        writer.write(">")
        if is_child_text_only(self):
            for node in self.childNodes:
                node.writexml(writer, '', '', '')
            writer.write("</%s>%s" % (self.tagName, newl))
        else:
            writer.write(newl)
            for node in self.childNodes:
                if node.nodeType == xml.dom.minidom.Node.TEXT_NODE and node.data.isspace():
                    pass
                else:
                    node.writexml(writer, indent + addindent, addindent, newl)
            writer.write("%s</%s>%s" % (indent, self.tagName, newl))
    else:
        writer.write("/>%s" % (newl))

xml.dom.minidom.Element.writexml = ignore_whitespace_writexml


class ServicePack(object):
    
    def __init__(self, node):
        self.__xml = node
    
    @property
    def name(self):
        return self.__xml.getAttribute('name')
    
    @property
    def files(self):
        result = []
        for filen in self.__xml.getElementsByTagName('file'):
            result.append(filen.getAttribute('name'))
        return result

    @property
    def instructions(self):
        result = []
        for instr in self.__xml.getElementsByTagName('instructions'):
            result.append(instr.getAttribute('name'))
        return result

class ReleaseMetadata(object):
    """ Create or read Metadata XML from SYMREC/SYMDEC. """
    
    def __init__(self, filename, service=None, product=None, release=None):
        self._filename = filename
        if filename and os.path.exists(filename):
            self._xml = xml.dom.minidom.parse(open(filename, "r"))
            releaseInformation = self._xml.getElementsByTagName(u"releaseInformation")
            if releaseInformation != []:
                self._releaseInformation = releaseInformation[0]
            else:
                self._releaseInformation = self._xml.createElement(u"releaseInformation")
            releaseDetails = self._xml.getElementsByTagName(u'releaseDetails')
            if releaseDetails != []:
                self._releaseDetails = releaseDetails[0]
            else:
                self._releaseDetails = self._xml.createElement(u'releaseDetails')
            releaseFiles = self._xml.getElementsByTagName(u'releaseFiles')
            if releaseFiles != []:
                self._releaseFiles = releaseFiles[0]
            else:
                self._releaseFiles = self._xml.createElement(u'releaseFiles')
                
            if service != None:
                self.service = service
            if product != None:
                self.product = product
            if release != None:
                self.release = release
        elif service!=None and product!=None and release!=None:
            self._xml = xml.dom.minidom.Document()
            self._releaseInformation = self._xml.createElement(u"releaseInformation")
            self._xml.appendChild(self._releaseInformation)
            self._releaseDetails = self._xml.createElement(u'releaseDetails')
            self._releaseInformation.appendChild(self._releaseDetails)
            releaseID = self._xml.createElement(u'releaseID')
            self._releaseDetails.appendChild(releaseID)
            
            #           service
            serv = self._xml.createElement(u'service')            
            xml_setattr(serv, 'name', unicode(service))
            releaseID.appendChild(serv)
            #           product
            prod = self._xml.createElement(u'product')
            xml_setattr(prod, 'name', unicode(product))
            releaseID.appendChild(prod)
            #           release
            rel = self._xml.createElement(u'release')
            xml_setattr(rel, 'name', unicode(release))
            releaseID.appendChild(rel)
            
            #    releaseFiles
            self._releaseFiles = self._xml.createElement(u'releaseFiles')
            self._releaseInformation.appendChild(self._releaseFiles)

            #    releaseFiles
            self._releaseInformation.appendChild(self._xml.createElement(u'externalFiles'))
        else:
            raise Exception("Error metadata file doesn't exists.")


    def get_dependsof(self):
        """ Return a ReleaseMetada object pointing to the dependency release. """
        if self.dependsof_service != None and self.dependsof_product != None and self.dependsof_release != None:
            filename = os.path.join(os.path.dirname(self._filename), "../../..",
                                self.dependsof_service,
                                self.dependsof_product,
                                self.dependsof_release)
            return ReleaseMetadata(find_latest_metadata(filename))
        else:
            return None


    def set_dependsof(self, filename):
        """ Setting the dependency release. """
        metadata  = ReleaseMetadata(filename)
        self.dependsof_service  = metadata.service
        self.dependsof_product  = metadata.product
        self.dependsof_release  = metadata.release

    def add_package(self, name, type=None, default=True, filters=None, extract="single", md5checksum=None, size=None):
        """ Adding a package to the metadata file. """
        # check if update mode
        package = None
        
        for pkg in self._xml.getElementsByTagName('package'):
            if (pkg.getAttribute('name').lower() == os.path.basename(name).lower()):
                package = pkg
                break
        
        # if not found create new package.
        if package is None:
            package = self._xml.createElement(u'package')
            self._releaseFiles.appendChild(package)
            
        xml_setattr(package, 'name', os.path.basename(name))
        if type != None:
            xml_setattr(package, 'type', type)
        else:
            xml_setattr(package, 'type', os.path.splitext(name)[1].lstrip('.'))
        xml_setattr(package, 'default', str(default).lower())
        xml_setattr(package, 'extract', extract)
        if filters and len(filters)>0:
            xml_setattr(package, 'filters', ','.join(filters))
            xml_setattr(package, 's60filter', ','.join(filters))
        else:
            xml_setattr(package, 'filters', '')
            xml_setattr(package, 's60filter', '')
        if md5checksum != None:
            xml_setattr(package, unicode("md5checksum"), unicode(md5checksum))
        if size != None:
            xml_setattr(package, unicode("size"), unicode(size))
        

    def keys(self):
        keys = []
        for pkg in self._releaseFiles.getElementsByTagName('package'):
            keys.append(pkg.getAttribute('name'))
        return keys

    def __getitem__(self, key):
        for pkg in self._releaseFiles.getElementsByTagName('package'):
            if pkg.getAttribute('name').lower() == key.lower():
                filters = []
                s60filters = []
                md5checksum = None
                size = None
                if pkg.hasAttribute(u'filters'):
                    filters = _cleanup_list(pkg.getAttribute('filters').split(','))
                if pkg.hasAttribute(u's60filter'):
                    s60filters = _cleanup_list(pkg.getAttribute('s60filter').split(','))
                if pkg.hasAttribute(u'md5checksum'):
                    md5checksum = pkg.getAttribute('md5checksum')
                if pkg.hasAttribute(u'size'):
                    size = pkg.getAttribute('size')
                return {'type': pkg.getAttribute('type'), 'extract': pkg.getAttribute('extract'), 'default': (pkg.getAttribute('default')=="true"), \
                         'filters': filters, 's60filter': s60filters, 'md5checksum': md5checksum, 'size': size}
        raise Exception("Key '%s' not found." % key)

    def __setitem__(self, key, value):
        self.add_package(key, value['type'], value['default'], value['filters'], value['extract'], value['md5checksum'], value['size'])

    def set_releasedetails_info(self, name, value, details="releaseID"):
        """ Generic function to set releaseid info. """
        detailsnode = None
        if self._releaseDetails.getElementsByTagName(details) == []:
            detailsnode = self._xml.createElement(details)
            self._releaseDetails.appendChild(detailsnode)
        else:
            detailsnode = self._releaseDetails.getElementsByTagName(details)[0]
        namenode = None
        if detailsnode.getElementsByTagName(name) == []:
            namenode = self._xml.createElement(name)
            namenode.setAttribute(u'name', unicode(value))
            detailsnode.appendChild(namenode)
        else:  
            namenode = detailsnode.getElementsByTagName(name)[0]
            namenode.setAttribute('name', value)

    
    def get_releasedetails_info(self, name, details="releaseID"):
        """ Generic function to extract releaseid info. """
        for group in self._releaseDetails.getElementsByTagName(details):
            for i in group.getElementsByTagName(name):
                return i.getAttribute('name')
        return None

    def getVariantPackage(self, variant_name):
        for variant in self._xml.getElementsByTagName('variant'):
            if variant.getAttribute('name').lower() == variant_name.lower():
                for x in variant.getElementsByTagName('file'):
                    return x.getAttribute('name')        

    def xml(self):
        """ Returning the XML as a string. """
        return self._xml.toprettyxml()
        
    def save(self, filename = None):
        """ Saving the XML into the provided filename. """
        if filename == None:
            filename = self._filename
        file_object = codecs.open(os.path.join(filename), 'w', "utf_8")
        file_object.write(self.xml())
        file_object.close()

    @property
    def servicepacks(self):
        """ Getting the service pack names. """
        result = []
        for sp in self._releaseInformation.getElementsByTagName('servicePack'):
            result.append(ServicePack(sp))
        return result

    filename = property(lambda self:self._filename)
    service = property(lambda self:self.get_releasedetails_info('service'), lambda self, value:self.set_releasedetails_info('service', value))
    product = property(lambda self:self.get_releasedetails_info('product'), lambda self, value:self.set_releasedetails_info('product', value))
    release = property(lambda self:self.get_releasedetails_info('release'), lambda self, value:self.set_releasedetails_info('release', value))
    dependsof_service = property(lambda self:self.get_releasedetails_info('service', 'dependsOf'), lambda self, value:self.set_releasedetails_info('service', value, 'dependsOf'))
    dependsof_product = property(lambda self:self.get_releasedetails_info('product', 'dependsOf'), lambda self, value:self.set_releasedetails_info('product', value, 'dependsOf'))
    dependsof_release = property(lambda self:self.get_releasedetails_info('release', 'dependsOf'), lambda self, value:self.set_releasedetails_info('release', value, 'dependsOf'))
    baseline_service = property(lambda self:self.get_releasedetails_info('service', 'previousBaseline'), lambda self, value:self.set_releasedetails_info('service', value, 'previousBaseline'))
    baseline_product = property(lambda self:self.get_releasedetails_info('product', 'previousBaseline'), lambda self, value:self.set_releasedetails_info('product', value, 'previousBaseline'))
    baseline_release = property(lambda self:self.get_releasedetails_info('release', 'previousBaseline'), lambda self, value:self.set_releasedetails_info('release', value, 'previousBaseline'))


class MD5Updater(ReleaseMetadata):
    """ Update Metadata XML already created from SYMREC/SYMDEC. """
    def __init__(self, filename):
        ReleaseMetadata.__init__(self, filename)
        self._filepath = os.path.dirname(filename)
                  
    def update(self):
        """ Update each existing package md5checksum and size attribute."""
        for name in self.keys():
            fullname = os.path.join(self._filepath, name)                
            if os.path.exists(fullname):
                result = self[name]
                result['md5checksum'] = unicode(fileutils.getmd5(fullname))
                result['size'] = unicode(os.path.getsize(fullname))
                self[name] = result


class ValidateReleaseMetadata(ReleaseMetadata):
    """ This class validate if a metadata file is stored in the correct location and
        if all deps exists.
    """
    def __init__(self, filename):
        ReleaseMetadata.__init__(self, filename)
        self.location = os.path.dirname(filename)
    
    def is_valid(self, checkmd5=True, checkPath=True):
        """ Run the validation mechanism. """
        status = os.path.join(os.path.dirname(self._filename), 'HYDRASTATUS.xml')
        if os.path.exists(status):
            hydraxml = xml.dom.minidom.parse(open(status, "r"))
            for t in hydraxml.getElementsByTagName('state')[0].childNodes:
                if t.nodeType == t.TEXT_NODE:
                    if t.nodeValue != 'Ready':
                        LOGGER.error("HYDRASTATUS.xml is not ready")
                        return False
        if checkPath:
            if os.path.basename(self.location) != self.release:
                LOGGER.error("Release doesn't match.")
                return False
            if os.path.basename(os.path.dirname(self.location)) != self.product:
                LOGGER.error("Product doesn't match.")
                return False
            if os.path.basename(os.path.dirname(os.path.dirname(self.location))) != self.service:
                LOGGER.error("Service doesn't match.")
                return False
        
        for name in self.keys():
            path = os.path.join(self.location, name)
            if not os.path.exists(path):
                LOGGER.error("%s doesn't exist." % path)
                return False
            try:
                LOGGER.debug("Trying to open %s" % path)
                content_file = open(path)
                content_file.read(1)
            except IOError:
                LOGGER.error("%s is not available yet" % path)
                return False
                
            if checkmd5 and self[name].has_key('md5checksum'):
                if self[name]['md5checksum'] != None:
                    if fileutils.getmd5(path).lower() != self[name]['md5checksum']:
                        LOGGER.error("%s md5checksum missmatch." % path)
                        return False

        for sp in self.servicepacks:
            for name in sp.files:
                path = os.path.join(self.location, name)
                if not os.path.exists(path):
                    LOGGER.error("%s doesn't exist." % path)
                    return False
            for name in sp.instructions:
                path = os.path.join(self.location, name)
                if not os.path.exists(path):
                    LOGGER.error("%s doesn't exist." % path)
                    return False
        
        dependency = self.get_dependsof()
        if dependency != None:
            return ValidateReleaseMetadata(dependency.filename).is_valid(checkmd5)
        return True

class MetadataMerger(object):
    """ Merge packages definition to the root metadata. """
    
    def __init__(self, metadata):
        """ Construct a metadata merger providing root metadata filename. """ 
        self._metadata = ReleaseMetadata(metadata)
                
    def merge(self, filename):
        """ Merge the content of filename into the root metadata. """
        metadata = ReleaseMetadata(filename)
        for name in metadata.keys():
            if name in self._metadata.keys():
                LOGGER.warning('Package %s already declared, overriding previous definition!' % name)        
            self._metadata[name] = metadata[name]

    def xml(self):
        """ Returning the XML as a string. """
        return self._metadata.xml()

    def save(self, filename = None):
        """ Saving the XML into the provided filename. """
        return self._metadata.save(filename)
 
class Metadata2TDD(ReleaseMetadata):

    def __init__(self, filename, includes=None, excludes=None):
        ReleaseMetadata.__init__(self, filename)
        if includes is None:
            includes = []
        if excludes is None:
            excludes = []
        self.location = os.path.dirname(filename)
        self.includes = includes
        self.excludes = excludes

    def archives_to_tdd(self, metadata):
        tdd = "\t[\n"
        for name in metadata.keys():
            path_ = os.path.join(os.path.dirname(metadata.filename), name)
            if (((len(self.includes) == 0) and metadata[name]['extract']) or (self.includes in metadata[name]['s60filter'])) and self.excludes not in metadata[name]['s60filter']:
                tdd += "\t\t{\n"
                tdd += "\t\t\t\"command\": \"unzip_%s\",\n" % metadata[name]['extract']
                tdd += "\t\t\t\"src\": \"%s\",\n" % os.path.normpath(path_).replace('\\', '/')
                tdd += "\t\t},\n"
        tdd += "\t],\n"
        return tdd
        
    def to_tdd(self):
        """ Generating a TDD file that contains a list of list of filenames. """
        tdd = "[\n"
        # generates unarchiving steps for dependency
        dependency = self.get_dependsof()
        if dependency != None:
            tdd += self.archives_to_tdd(dependency)
        # generates unarchiving steps
        tdd += self.archives_to_tdd(self)
        tdd += "]\n"
        return tdd



def find_latest_metadata(releasedir):
    """ Finding the release latest release metadata file. """ 
    try:
        metadatas = []
        for filename in os.listdir(releasedir):
            if re.match(r'^release_metadata(_\d+)?\.xml$', filename, re.I) is not None:
                LOGGER.debug("Found %s" % filename)
                metadatas.append(filename)
        # reverse the order...
        metadatas.sort(reverse=True)
        if len(metadatas) > 0:
            return os.path.normpath(os.path.join(releasedir, metadatas[0]))
    except Exception, exc:
        LOGGER.error(exc)
        return None
    return None

class ValidateReleaseMetadataCached(ValidateReleaseMetadata):
    """ Cached version of the metadata validation. """
    def __init__(self, filename, cachefile=None):
        ValidateReleaseMetadata.__init__(self, filename)
        self.__cachefile = cachefile

    def is_valid(self, checkmd5=True, checkPath=True):
        """ Check if file is in the local cache.
            Add valid release to the cache.
        """
        metadatas = self.load_cache()
        if self.in_cache(metadatas, os.path.normpath(self._filename)):
            LOGGER.debug("Release found in cache.")
            return self.value_from_cache(metadatas, os.path.normpath(self._filename))
        else:
            result = ValidateReleaseMetadata.is_valid(self, checkmd5, checkPath)        
            LOGGER.debug("Updating the cache.")
            metadatas.append([os.path.normpath(self._filename), result])
            self.update_cache(metadatas)
        return result

    def in_cache(self, metadatas, key):
        for metadata in metadatas:
            if metadata[0] == key:
                return True 
        return False
    
    def value_from_cache(self, metadatas, key):
        for metadata in metadatas:
            if metadata[0] == key:
                return metadata[1]
        return None
    
    def load_cache(self):
        metadatas = []
        if self.__cachefile is not None and os.path.exists(self.__cachefile):
            f = open(self.__cachefile, "rb")
            for row in csv.reader(f):
                if len(row) == 2:
                    metadatas.append([os.path.normpath(row[0]), row[1].lower() == "true"])
                elif len(row) == 1:
                    # backward compatibility with old cache.
                    metadatas.append([os.path.normpath(row[0]), True])
            f.close()
        return metadatas

    def update_cache(self, metadatas):
        if self.__cachefile is not None and os.path.exists(os.path.dirname(self.__cachefile)):
            f = open(self.__cachefile, "wb")
            writer = csv.writer(f)
            writer.writerows(metadatas)
            f.close()

class ValidateTicklerReleaseMetadata(ValidateReleaseMetadataCached):
    """ This class validate if a metadata file is stored in the correct location and
        if all deps exists.
    """
    def __init__(self, filename):
        ReleaseMetadata.__init__(self, filename)
        self.location = os.path.dirname(filename)
    
    def is_valid(self, checkmd5=True):
        """ Run the validation mechanism. """
        tickler_path = os.path.join(self.location,"TICKLER")
        if not os.path.exists(tickler_path):
            LOGGER.error("Release not available yet")
            return False
        else:
            return ValidateReleaseMetadataCached.is_valid(self, checkmd5)
