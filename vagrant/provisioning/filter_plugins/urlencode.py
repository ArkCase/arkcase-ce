try:
    from urllib import quote  # Python 2.X
except ImportError:
    from urllib.parse import quote  # Python 3+

def urlencode(string):
    return quote(string)  #.decode('utf8')


class FilterModule(object):
    ''' ArkCase Jinja Filters '''

    def filters(self):
        return {
            'urlencode': urlencode
        }
