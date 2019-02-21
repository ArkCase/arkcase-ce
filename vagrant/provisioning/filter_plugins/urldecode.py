try:
    from urllib import unquote  # Python 2.X
except ImportError:
    from urllib.parse import unquote  # Python 3+

def urldecode(string):
    return unquote(string)  #.decode('utf8')


class FilterModule(object):
    ''' ArkCase Jinja Filters '''

    def filters(self):
        return {
            'urldecode': urldecode
        }
