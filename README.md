vimp4python
===========

Perforce integration for Vim (for Windows)

This plugin was originally published in the [Perforce Blog][blog].

Modifications include:
* side-by-side diff using vim's internal diff engine
* changes to the default key bindings for easier remembering
* output formatting changes on a few commands
* changes to the ruler to make it more friendly
* removed s: prefix from most of the plugins functions

This plugin uses the [P4Python API][man] which can be downloaded from the
Perforce APIs download page.  However, as of this writing (2014-10-28), the
installed P4API.pyd on Windows does not load correctly when running python
scripts under vim. This is due to the embedded manifest file. The best
solution is to build the p4python API from source.

## Build p4python from source (Windows)

* Download the source from the [Perforce APIs][download] download page

        wget http://www.perforce.com/downloads/perforce/r14.1/bin.tools/p4python.tgz

* Extract the files

        tar xvzf p4python.tgz

* Download the [Perforce C++ API][cppapi] from the Perforce FTP site.
    - The files are under the `<release>/<platform>` folder (e.g.
      ftp://ftp.perforce.com/perforce/r14.1/bin.ntx86/)
    - Download p4api_vs2010_static.zip

            wget ftp://ftp.perforce.com/perforce/r14.1/bin.ntx86/p4api_vs2010_static.zip

* Extract the C++ api

        unzip p4api_vs2010_static.zip

* Open Visual Studio 2010 command line prompt and set the environment for python build using VS2010

        SET VS90COMNTOOLS=%VS100COMNTOOLS%

* Build/install

        python setup.py build --apidir (Perforce C++ API path)
        python setup.py install --apidir (Perforce C++ API path)


[blog]: http://www.perforce.com/blog/101123/perforce-integration-vim-courtesy-p4python
[man]: http://www.perforce.com/perforce/doc.current/manuals/p4script/03_python.html
[download]: http://www.perforce.com/product/components/apis
[cppapi]: ftp://ftp.perforce.com/perforce/
