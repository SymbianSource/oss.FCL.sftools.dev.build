#============================================================================ 
#Name        : site.py 
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

# Duplicating setuptools' site.py...
def __boot():
    PYTHONPATH = []    
    if sys.platform=='win32':
        PYTHONPATH.append(os.path.join(sys.prefix, 'lib'))
    if not (os.environ.get('PYTHONPATH') is None or (sys.platform=='win32' and not os.environ.get('PYTHONPATH'))):
        PYTHONPATH.extend(os.environ.get('PYTHONPATH').split(os.pathsep))
    pic = getattr(sys,'path_importer_cache',{})
    stdpath = sys.path[len(PYTHONPATH):]
    mydir = os.path.dirname(__file__)
    known_paths = dict([(makepath(item)[1],1) for item in sys.path]) # 2.2 comp

    oldpos = getattr(sys,'__egginsert',0)   # save old insertion position
    sys.__egginsert = 0                     # and reset the current one

    for item in PYTHONPATH:
        addsitedir(item)
        item_site_packages = os.path.join(item, 'site-packages')
        if os.path.exists(item_site_packages):
            addsitedir(item_site_packages)

    sys.__egginsert += oldpos           # restore effective old position

    d,nd = makepath(stdpath[0])
    insert_at = None
    new_path = []

    for item in sys.path:
        p,np = makepath(item)

        if np==nd and insert_at is None:
            # We've hit the first 'system' path entry, so added entries go here
            insert_at = len(new_path)

        if np in known_paths or insert_at is None:
            new_path.append(item)
        else:
            # new path after the insert point, back-insert it
            new_path.insert(insert_at, item)
            insert_at += 1

    sys.path[:] = new_path
    
import sys
import os
import __builtin__

def makepath(*paths):
    dir = os.path.abspath(os.path.join(*paths))
    return dir, os.path.normcase(dir)

def abs__file__():
    """Set all module' __file__ attribute to an absolute path"""
    for m in sys.modules.values():
        try:
            m.__file__ = os.path.abspath(m.__file__)
        except AttributeError:
            continue

try:
    set
except NameError:
    class set:
        def __init__(self, args=()):
            self.d = {}
            for v in args:
                self.d[v] = None
        def __contains__(self, key):
            return key in self.d
        def add(self, key):
            self.d[key] = None

def removeduppaths():
    """ Remove duplicate entries from sys.path along with making them
    absolute"""
    # This ensures that the initial path provided by the interpreter contains
    # only absolute pathnames, even if we're running from the build directory.
    L = []
    known_paths = set()
    for dir in sys.path:
        # Filter out duplicate paths (on case-insensitive file systems also
        # if they only differ in case); turn relative paths into absolute
        # paths.
        dir, dircase = makepath(dir)
        if not dircase in known_paths:
            L.append(dir)
            known_paths.add(dircase)
    sys.path[:] = L
    return known_paths

def _init_pathinfo():
    """Return a set containing all existing directory entries from sys.path"""
    d = set()
    for dir in sys.path:
        try:
            if os.path.isdir(dir):
                dir, dircase = makepath(dir)
                d.add(dircase)
        except TypeError:
            continue
    return d

def addpackage(sitedir, name, known_paths, exclude_packages=()):
    """Add a new path to known_paths by combining sitedir and 'name' or execute
    sitedir if it starts with 'import'"""
    import fnmatch
    if known_paths is None:
        _init_pathinfo()
        reset = 1
    else:
        reset = 0
    fullname = os.path.join(sitedir, name)
    try:
        f = open(fullname, "rU")
    except IOError:
        return
    try:
        for line in f:
            if line.startswith("#"):
                continue
            found_exclude = False
            for exclude in exclude_packages:
                if exclude(line):
                    found_exclude = True
                    break
            if found_exclude:
                continue
            if line.startswith("import"):
                exec line
                continue
            line = line.rstrip()
            dir, dircase = makepath(sitedir, line)
            if not dircase in known_paths and os.path.exists(dir):
                sys.path.append(dir)
                known_paths.add(dircase)
    finally:
        f.close()
    if reset:
        known_paths = None
    return known_paths

def addsitedir(sitedir, known_paths=None, exclude_packages=()):
    """Add 'sitedir' argument to sys.path if missing and handle .pth files in
    'sitedir'"""
    if known_paths is None:
        known_paths = _init_pathinfo()
        reset = 1
    else:
        reset = 0
    sitedir, sitedircase = makepath(sitedir)
    if not sitedircase in known_paths:
        sys.path.append(sitedir)        # Add path component
    try:
        names = os.listdir(sitedir)
    except os.error:
        return
    names.sort()
    for name in names:
        if name.endswith(os.extsep + "pth"):
            addpackage(sitedir, name, known_paths,
                       exclude_packages=exclude_packages)
    if reset:
        known_paths = None
    return known_paths

def addsitepackages(known_paths):
    """Add site-packages (and possibly site-python) to sys.path"""
    prefixes = [os.path.join(sys.prefix, "local"), sys.prefix]
    if sys.exec_prefix != sys.prefix:
        prefixes.append(os.path.join(sys.exec_prefix, "local"))
    for prefix in prefixes:
        if prefix:
            if sys.platform in ('os2emx', 'riscos'):
                sitedirs = [os.path.join(prefix, "Lib", "site-packages")]
            elif os.sep == '/':
                sitedirs = [os.path.join(prefix,
                                         "lib",
                                         "python" + sys.version[:3],
                                         "site-packages"),
                            os.path.join(prefix, "lib", "site-python")]
                try:
                    # sys.getobjects only available in --with-pydebug build
                    # pylint: disable-msg=E1101
                    sys.getobjects
                    sitedirs.insert(0, os.path.join(sitedirs[0], 'debug'))
                except AttributeError:
                    pass
            else:
                sitedirs = [prefix, os.path.join(prefix, "lib", "site-packages")]
            if sys.platform == 'darwin':
                sitedirs.append( os.path.join('/opt/local', 'lib', 'python' + sys.version[:3], 'site-packages') )
                # for framework builds *only* we add the standard Apple
                # locations. Currently only per-user, but /Library and
                # /Network/Library could be added too
                if 'Python.framework' in prefix:
                    home = os.environ.get('HOME')
                    if home:
                        sitedirs.append(
                            os.path.join(home,
                                         'Library',
                                         'Python',
                                         sys.version[:3],
                                         'site-packages'))
            for sitedir in sitedirs:
                if os.path.isdir(sitedir):
                    addsitedir(sitedir, known_paths,
                               exclude_packages=[lambda line: 'setuptools' in line])
    return None

def setquit():
    """Define new built-ins 'quit' and 'exit'.
    These are simply strings that display a hint on how to exit.

    """
    if os.sep == ':':
        exit = 'Use Cmd-Q to quit.'
    elif os.sep == '\\':
        exit = 'Use Ctrl-Z plus Return to exit.'
    else:
        exit = 'Use Ctrl-D (i.e. EOF) to exit.'
    __builtin__.quit = __builtin__.exit = exit


class _Printer(object):
    """interactive prompt objects for printing the license text, a list of
    contributors and the copyright notice."""

    MAXLINES = 23

    def __init__(self, name, data, files=(), dirs=()):
        self.__name = name
        self.__data = data
        self.__files = files
        self.__dirs = dirs
        self.__lines = None

    def __setup(self):
        if self.__lines:
            return
        data = None
        for dir in self.__dirs:
            for filename in self.__files:
                filename = os.path.join(dir, filename)
                try:
                    fp = file(filename, "rU")
                    data = fp.read()
                    fp.close()
                    break
                except IOError:
                    pass
            if data:
                break
        if not data:
            data = self.__data
        self.__lines = data.split('\n')
        self.__linecnt = len(self.__lines)

    def __repr__(self):
        self.__setup()
        if len(self.__lines) <= self.MAXLINES:
            return "\n".join(self.__lines)
        else:
            return "Type %s() to see the full %s text" % ((self.__name,)*2)

    def __call__(self):
        self.__setup()
        prompt = 'Hit Return for more, or q (and Return) to quit: '
        lineno = 0
        while 1:
            try:
                for i in range(lineno, lineno + self.MAXLINES):
                    print self.__lines[i]
            except IndexError:
                break
            else:
                lineno += self.MAXLINES
                key = None
                while key is None:
                    key = raw_input(prompt)
                    if key not in ('', 'q'):
                        key = None
                if key == 'q':
                    break

def setcopyright():
    """Set 'copyright' and 'credits' in __builtin__"""
    __builtin__.copyright = _Printer("copyright", sys.copyright)
    if sys.platform[:4] == 'java':
        __builtin__.credits = _Printer(
            "credits",
            "Jython is maintained by the Jython developers (www.jython.org).")
    else:
        __builtin__.credits = _Printer("credits", """\
    Thanks to CWI, CNRI, BeOpen.com, Zope Corporation and a cast of thousands
    for supporting Python development.  See www.python.org for more information.""")
    here = os.path.dirname(os.__file__)
    __builtin__.license = _Printer(
        "license", "See http://www.python.org/%.3s/license.html" % sys.version,
        ["LICENSE.txt", "LICENSE"],
        [os.path.join(here, os.pardir), here, os.curdir])


class _Helper(object):
    """Define the built-in 'help'.
    This is a wrapper around pydoc.help (with a twist).

    """

    def __repr__(self):
        return "Type help() for interactive help, " \
               "or help(object) for help about object."
    def __call__(self, *args, **kwds):
        import pydoc
        return pydoc.help(*args, **kwds)

def sethelper():
    __builtin__.help = _Helper()

def aliasmbcs():
    """On Windows, some default encodings are not provided by Python,
    while they are always available as "mbcs" in each locale. Make
    them usable by aliasing to "mbcs" in such a case."""
    if sys.platform == 'win32':
        import locale, codecs
        enc = locale.getdefaultlocale()[1]
        if enc.startswith('cp'):            # "cp***" ?
            try:
                codecs.lookup(enc)
            except LookupError:
                import encodings
                encodings._cache[enc] = encodings._unknown
                encodings.aliases.aliases[enc] = 'mbcs'

def setencoding():
    """Set the string encoding used by the Unicode implementation.  The
    default is 'ascii', but if you're willing to experiment, you can
    change this."""
    encoding = "ascii" # Default value set by _PyUnicode_Init()
    if 0:
        # Enable to support locale aware default string encodings.
        import locale
        loc = locale.getdefaultlocale()
        if loc[1]:
            encoding = loc[1]
    if 0:
        # Enable to switch off string to Unicode coercion and implicit
        # Unicode to string conversion.
        encoding = "undefined"
    if encoding != "ascii":
        # On Non-Unicode builds this will raise an AttributeError...
        sys.setdefaultencoding(encoding) # Needs Python Unicode build !


def execsitecustomize():
    """Run custom site specific code, if available."""
    try:
        import sitecustomize
    except ImportError:
        pass

def fixup_setuptools():
    """Make sure our setuptools monkeypatch is in place"""
    for i in range(len(sys.path)):
        if sys.path[i].find('setuptools') != -1:
            path = sys.path[i]
            del sys.path[i]
            sys.path.append(path)

def main():
    abs__file__()
    paths_in_sys = removeduppaths()
    if include_site_packages:
        paths_in_sys = addsitepackages(paths_in_sys)
    setquit()
    setcopyright()
    sethelper()
    aliasmbcs()
    setencoding()
    execsitecustomize()
    # Remove sys.setdefaultencoding() so that users cannot change the
    # encoding after initialization.  The test for presence is needed when
    # this module is run as a script, because this code is executed twice.
    if hasattr(sys, "setdefaultencoding"):
        del sys.setdefaultencoding
    __boot()
    fixup_setuptools()
    


include_site_packages = False



main()
