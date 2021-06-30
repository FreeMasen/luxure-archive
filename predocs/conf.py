extensions = [
    'sphinxcontrib.luadomain',
    'sphinx_lua',
    'sphinx_rtd_theme',
    'm2r2',
]

source_suffix = ['.rst', '.md']


# a list of lua source root
lua_source_path = ['./luxure'] 
html_title = 'Luxure'
html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'logo_only': True
}
html_short_title = 'Luxure'
html_logo = 'home.svg'
html_baseurl= '/luxure/'
