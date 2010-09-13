#============================================================================ 
#Name        : widgets.py 
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
""" handles components in XML documents"""

# pylint: disable=E1101

import xml.dom.minidom
class Widget:
    """ Class Widget represents a component in an xml document """
    def __init__(self):
        pass
    
    def getDOMContainer(self):
        """get DOM container"""
        pass
    
    
class Box(Widget):
    """ A widget of type Box """
    def __init__(self, doc, container, divId = "mb", divClass = "mc"):
        Widget.__init__(self)
        doc_1 = doc.createElementNS("", "div")
        doc_1.setAttributeNS("", "id", divId)
        container.appendChild(doc_1)
        m_c = doc.createElementNS("", "div")
        m_c.setAttributeNS("", "class", divClass)
        doc_1.appendChild(m_c)
        self.__doc = doc
        self.__title = None
        self.__mc = m_c
        
    def setTitle(self, title=""):
        """set the title"""
        if self.__title == None:
            t_doc = self.__doc.createElementNS("", "h1")
            self.__mc.insertBefore(t_doc, self.__mc.firstChild)
            self.__title = self.__doc.createTextNode(title)
            t_doc.appendChild(self.__title)
        self.__title.data = title

    def getDOMContainer(self):
        """get DOM container"""
        return self.__mc
    
class Summary(Box):
    """ A widget representing a summary component """
    def __init__(self, doc, container):
        Box.__init__(self, doc, container, divId = "s_mb", divClass = "s_mc")
        self.__table = doc.createElementNS("", "table")
        self.__table.setAttributeNS("", "cellspacing", "0")
        self.__table.setAttributeNS("", "cellpadding", "0")
        self.__table.setAttributeNS("", "border", "0")
        self.__table.setAttributeNS("", "width", "100%")
        self.__table.appendChild(self._Box__doc.createTextNode(""))
        div = self._Box__doc.createElementNS("", "div")
        div.setAttributeNS("", "class", "t_wrapper")
        div.appendChild(self.__table)
        self.getDOMContainer().appendChild(div)
        self.__table_stat = None
        self.setTitle()

    
    def addElement(self, tag, value):
        """add Element"""
        row = self._Box__doc.createElementNS("", "tr")
        #Tag
        t_d = self._Box__doc.createElementNS("", "td")
        t_d.setAttributeNS("", "valign", "top")
        t_d.setAttributeNS("", "nowrap", "nowrap")
        div = self._Box__doc.createElementNS("", "div")
        div.setAttributeNS("", "class", "s_tag")
        div.appendChild(self._Box__doc.createTextNode(tag))
        t_d.appendChild(div)
        row.appendChild(t_d)
        
        # Value
        t_d = self._Box__doc.createElementNS("", "td")
        t_d.setAttributeNS("", "width", "100%")        
        div = self._Box__doc.createElementNS("", "div")
        div.setAttributeNS("", "class", "s_val")
        div.appendChild(self._Box__doc.createTextNode(value))
        t_d.appendChild(div)
        row.appendChild(t_d)

        self.__table.appendChild(row)

    def addStatistics(self, type_, value):
        """add Statistics"""
        if self.__table_stat == None:
            head1 = self._Box__doc.createElementNS("", "h1")
            head1.appendChild(self._Box__doc.createTextNode("Global Statistics"))
            self.getDOMContainer().appendChild(head1)
                            
            div = self._Box__doc.createElementNS("", "div")
            div.setAttributeNS("", "class", "t_wrapper")
            self.getDOMContainer().appendChild(div)
            self.__table_stat = self._Box__doc.createElementNS("", "table")
            self.__table_stat.setAttributeNS("", "cellspacing", "0")
            self.__table_stat.setAttributeNS("", "cellpadding", "0")
            self.__table_stat.setAttributeNS("", "border", "0")
            self.__table_stat.setAttributeNS("", "width", "100%")
            div.appendChild(self.__table_stat)
        
            row = self._Box__doc.createElementNS("", "tr")
            self.__table_stat.appendChild(row)
            self.__table_stat = row

        t_d = self._Box__doc.createElementNS("", "td")
        div = self._Box__doc.createElementNS("", "div")
        div.setAttributeNS("", "class", "gbl_cnt_" + type_)
        div.appendChild(self._Box__doc.createTextNode("%d %ss" % (value, type_)))
        t_d.appendChild(div)
        self.__table_stat.appendChild(t_d)
          
    
    
class Event(Widget):
    """ A widget representing an event component """
    def __init__(self, doc, container, id_):
        Widget.__init__(self)
        self.__doc = doc
        node_head = doc.createElementNS("", "div")
        node_head.setAttributeNS("", "class", "node_head")
        container.appendChild(node_head)

        link = doc.createElementNS("", "a")
        link.setAttributeNS("", "href", "javascript:ToggleNode('Img%d')" % id_)
        node_head.appendChild(link)
        
        span = doc.createElementNS("", "span")
        span.setAttributeNS("", "id", "Img%d" % id_)
        span.setAttributeNS("", "style", "background:url(http://fawww.europe.nokia.com/isis/isis_interface/img/icons/button_open.gif) no-repeat")
        link.appendChild(span)

        stitle = doc.createElementNS("", "span")
        stitle.setAttributeNS("", "class", "node_title")
        self.__title = doc.createTextNode("")
        stitle.appendChild(self.__title)
        span.appendChild(stitle)
        
        # shaow all
        showall = doc.createElementNS("", "a")
        showall.setAttributeNS("", "href", "javascript:ShowChilds('Img%d')"  % id_)
        span = doc.createElementNS("", "span")
        span.setAttributeNS("", "class", "node_action")
        span.appendChild(doc.createTextNode("[Show All]"))
        showall.appendChild(span)
        
        #hide all
        hideall = doc.createElementNS("", "a")
        hideall.setAttributeNS("", "href", "javascript:HideChilds('Img%d')" % id_)
        span = doc.createElementNS("", "span")
        span.setAttributeNS("", "class", "node_action")
        span.appendChild(doc.createTextNode("[Hide All]"))
        hideall.appendChild(span)
        
        #toggle node
        self.__togglenode = doc.createElementNS("", "a")
        self.__togglenode.setAttributeNS("", "href", "javascript:ToggleNode('Img%d')" % id_)
        self.__togglenode.appendChild(doc.createTextNode(""))
        # append container
        node_head.appendChild(showall)
        node_head.appendChild(hideall)
        node_head.appendChild(self.__togglenode)

        contentx = doc.createElementNS("", "div")
        contentx.setAttributeNS("", "id", "Content%d" % id_)
        contentx.setAttributeNS("", "style", "display:none")
        container.appendChild(contentx)
        content = doc.createElementNS("", "div")
        content.setAttributeNS("", 'class', "node_content")
        content.appendChild(doc.createTextNode(""))
        contentx.appendChild(content)
        self.__container = content
        self.__node_info = None
        
    def setTitle(self, title = ""):
        """set Title"""
        self.__title.data = title

    def addStatistics(self, type_, value):
        """add Statistics"""
        if self.__node_info == None:
            self.__node_info = self.__doc.createElementNS("", "span")
            self.__node_info.setAttributeNS("", "class", "node_info")
            self.__togglenode.appendChild(self.__node_info)
        span = self.__doc.createElementNS("", "span")
        span.setAttributeNS("", "class","cnt_%s" % type_)
        span.appendChild(self.__doc.createTextNode("%d %ss" % (value, type_)))
        self.__node_info.appendChild(span)
          #<span class="node_info">
          #  <span class="cnt_warning">2 warnings</span>
          #</span>

    def getDOMContainer(self):
        """get DOM Container"""
        return self.__container


class Header(Widget):
    """ A widget representing a Header section """
    def __init__(self, doc, container):
        Widget.__init__(self)
        self.__doc = doc
        h_wrapper = self.__doc.createElementNS("", "div")
        h_wrapper.setAttributeNS("", "id", "h_wrapper")
        h_elmt = self.__doc.createElementNS("", "div")
        h_elmt.setAttributeNS("", "class", "h_elmt")
        h_wrapper.appendChild(h_elmt)
        container.appendChild(h_wrapper)
        #title
        t_elem = self.__doc.createElementNS("", "div")
        self.__title = doc.createTextNode("")
        t_elem.appendChild(self.__title)
        t_elem.setAttributeNS("", "class", "h_title")
        h_elmt.appendChild(t_elem)
        #subtitle
        t_elem = self.__doc.createElementNS("", "div")
        self.__subtitle = doc.createTextNode("")
        t_elem.appendChild(self.__subtitle)
        t_elem.setAttributeNS("", "class", "h_subtitle")
        h_elmt.appendChild(t_elem)
        
        
        
    def setTitle(self, title):
        """set Title"""
        self.__title.data = title
        
    def setSubTitle(self, title):
        """set Sub Title"""
        self.__subtitle.data = title

    def getDOMContainer(self):
        """get DOM Container"""
        return None

class Footer(Widget):
    """ A widget representing a footer section """
    def __init__(self, doc, container):
        Widget.__init__(self)
        self.__doc = doc
        h_wrapper = self.__doc.createElementNS("", "div")
        h_wrapper.setAttributeNS("", "id", "f_wrapper")
        h_elmt = self.__doc.createElementNS("", "div")
        h_elmt.setAttributeNS("", "class", "f_elmt")
        h_wrapper.appendChild(h_elmt)
        container.appendChild(h_wrapper)
        #title
        t_elem = self.__doc.createElementNS("", "div")
        self.__title = doc.createTextNode("")
        t_elem.appendChild(self.__title)
        t_elem.setAttributeNS("", "class", "f_title")
        h_elmt.appendChild(t_elem)
        #subtitle
        t_elem = self.__doc.createElementNS("", "div")
        self.__subtitle = doc.createTextNode("")
        t_elem.appendChild(self.__subtitle)
        t_elem.setAttributeNS("", "class", "f_subtitle")
        h_elmt.appendChild(t_elem)
        
    def setTitle(self, title):
        """set Title"""
        self.__title.data = title
        
    def setSubTitle(self, title):
        """set Sub Title"""
        self.__subtitle.data = title
    
class Text(Widget):
    """ A widget representing a text component """
    def __init__(self, doc, container):
        Widget.__init__(self)
        self.__doc = doc
        self.__div = self.__doc.createElementNS("", "div")
        self.__div.setAttributeNS("", "class", "icn_dft")
        container.appendChild(self.__div)
    
    def setIcon(self, name):
        """set Icon"""
        self.__div.setAttributeNS("", "class", name)

    def appendText(self, text):
        """append Text"""
        def pushContent(arg):
            """push Content"""
            self.getDOMContainer().appendChild(self.__doc.createTextNode(arg))
            self.getDOMContainer().appendChild(self.__doc.createElementNS("","br"))
        [pushContent(line) for line in text.strip().split("\n")]

    def getDOMContainer(self):
        """get DOM Container"""
        return self.__div

class RawText(Text):
    """ This class represents a raw text component """
    def appendText(self, text):
        """append Text"""
        for child in xml.dom.minidom.parseString("<xhtml>" + text.strip() + "</xhtml>").documentElement.childNodes:
            self.getDOMContainer().appendChild(child.cloneNode(True))

class BoldText(Text):
    """ This class represents a bold text component """
    def __init__(self, doc, container):
        Text.__init__(self, doc, container)
        self.__bold = doc.createElementNS("","b")
        self._Text__div.appendChild(self.__bold)
        
    def getDOMContainer(self):
        """get DOM COntainer"""
        return self.__bold
