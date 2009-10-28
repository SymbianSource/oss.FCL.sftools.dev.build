# -*- coding: utf-8 -*-
"""
    sphinx._jinja
    ~~~~~~~~~~~~~

    Jinja glue.

    :copyright: 2007-2008 by Georg Brandl, Horst Gutmann.
    :license: BSD.
"""

import codecs
from os import path

from sphinx.util import mtimes_of_files
from sphinx.application import TemplateBridge

from jinja import Environment
from jinja.loaders import BaseLoader
from jinja.exceptions import TemplateNotFound


def babel_extract(fileobj, keywords, comment_tags, options):
    """
    Simple extractor to get some basic Babel support.
    """
    env = Environment()
    for lineno, sg, pl in env.get_translations_for_string(fileobj.read()):
        yield lineno, None, (sg, pl), ''


class SphinxFileSystemLoader(BaseLoader):
    """
    A loader that loads templates either relative to one of a list of given
    paths, or from an absolute path.
    """

    def __init__(self, basepath, extpaths):
        self.basepath = path.abspath(basepath)
        self.extpaths = map(path.abspath, extpaths)
        self.searchpaths = self.extpaths + [self.basepath]

    def get_source(self, environment, name, parent):
        name = name.replace('/', path.sep)
        if name.startswith('!'):
            name = name[1:]
            if not path.exists(path.join(self.basepath, name)):
                raise TemplateNotFound(name)
            filename = path.join(self.basepath, name)
        elif path.isabs(name):
            if not path.exists(name):
                raise TemplateNotFound(name)
            filename = name
        else:
            for searchpath in self.searchpaths:
                if path.exists(path.join(searchpath, name)):
                    filename = path.join(searchpath, name)
                    break
            else:
                raise TemplateNotFound(name)
        f = codecs.open(filename, 'r', environment.template_charset)
        try:
            return f.read()
        finally:
            f.close()


class TranslatorEnvironment(Environment):
    class _Translator(object):
        def __init__(self, translator):
            self.trans = translator

        def gettext(self, string):
            return self.trans.ugettext(string)

        def ngettext(self, singular, plural, n):
            return self.trans.ungettext(singular, plural, n)

    def __init__(self, *args, **kwargs):
        self.translator = kwargs['translator']
        del kwargs['translator']
        super(TranslatorEnvironment, self).__init__(*args, **kwargs)

    def get_translator(self, context):
        return TranslatorEnvironment._Translator(self.translator)


class BuiltinTemplates(TemplateBridge):
    def init(self, builder):
        self.templates = {}
        base_templates_path = path.join(path.dirname(__file__), 'templates')
        ext_templates_path = [path.join(builder.confdir, dir)
                              for dir in builder.config.templates_path]
        self.templates_path = [base_templates_path] + ext_templates_path
        loader = SphinxFileSystemLoader(base_templates_path, ext_templates_path)
        if builder.translator is not None:
            self.jinja_env = TranslatorEnvironment(loader=loader,
                    friendly_traceback=False, translator=builder.translator)
        else:
            self.jinja_env = Environment(loader=loader,
                    # disable traceback, more likely that something
                    # in the application is broken than in the templates
                    friendly_traceback=False)

    def newest_template_mtime(self):
        return max(mtimes_of_files(self.templates_path, '.html'))

    def render(self, template, context):
        if template in self.templates:
            return self.templates[template].render(context)
        templateobj = self.templates[template] = \
                      self.jinja_env.get_template(template)
        return templateobj.render(context)
