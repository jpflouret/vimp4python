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
[Perforce APIs][download] download page.  However, as of this writing
(2014-10-28), the installed P4API.pyd does not load correctly when running
python scripts under vim. This is due to the embedded manifest file. The
simplest solution is to edit the P4API.pyd DLL with a resource editor (like
[ResEdit] (http://www.resedit.net/)) and delete the embedded manifest
resource.

Note that this plugin only works on Microsoft Windows platforms since the
P4Python API is only available for those platforms.

[blog]: http://www.perforce.com/blog/101123/perforce-integration-vim-courtesy-p4python
[man]: http://www.perforce.com/perforce/doc.current/manuals/p4script/03_python.html
[download]: http://www.perforce.com/product/components/apis
