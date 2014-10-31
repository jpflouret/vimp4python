" VIM integration via P4Python
" Depends on P4Python API
" P4RevGraph requires perl and Graph::Easy module
" Uses the connection environment from the current working directory.
" Oriented towards commands that can be run on a single file.
" Get help by typing :help vimp4python.

"
" Copyright (c) Perforce Software, Inc., 1997-2010. All rights reserved
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1.  Redistributions of source code must retain the above copyright
"     notice, this list of conditions and the following disclaimer.
"
" 2.  Redistributions in binary form must reproduce the above copyright
"     notice, this list of conditions and the following disclaimer in the
"     documentation and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
" 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
" LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
" FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE
" SOFTWARE, INC. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
" SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
" LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
" DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
" ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
" TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
" THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
" DAMAGE.
"
" User contributed content on the Perforce Public Depot is not supported by Perforce,
" although it may be supported by its author. This applies to all contributions
" even those submitted by Perforce employees.
"
" Modified by JP Flouret

"
" Standard code to avoid loading twice and to allow not loading
" Also detects if python is available
"
if exists("loaded_vimp4python")
    finish
endif
let loaded_vimp4python=1

if (!has('win32'))
    finish
endif

if (has('python') || has('python/dyn'))
    let loaded_vimp4python=1
else
    echoerr "vimp4python requires python"
    finish
endif

if (!exists("g:perforceNoInitialFstat"))
    let g:perforceNoInitialFstat = 0
endif

"
" check for P4Python API
"
python << EOF
try:
    import vim, P4
    p4 = P4.P4()
    vim.command("let b:hasp4 = \"1\"")
except:
    vim.command("let b:hasp4 = \"0\"")
EOF
if b:hasp4 == "0"
    echoerr "Failed to load P4Python API"
    finish
endif

python << EOF
from operator import itemgetter
def vimp4_FormatTable(keys, data, sortBy=None):

    if sortBy:
        data = sorted(data, key=itemgetter(sortBy))

    column_widths = []

    header_divider = []
    for name in keys:
        header_divider.append('=' * len(name))
    header_divider = dict(zip(keys, header_divider))
    data.insert(0, header_divider)
    header = dict(zip(keys, keys))
    data.insert(0, header)

    for key in keys:
        column_widths.append(max(len(str(column[key])) for column in data))
    key_width_pair = zip(keys, column_widths)

    format = ('%-*s ' * len(keys)).strip() + '\n'
    formatted_data = ''
    for element in data:
        data_to_format = []
        for pair in key_width_pair:
            data_to_format.append(pair[1])
            data_to_format.append(element[pair[0]])
        formatted_data += format % tuple(data_to_format)
    return formatted_data
EOF

" set this to 0 to disable ruler calls
let P4SetRuler = 1

"
" define the mappings that provide the user interface to this plug-in
"
augroup vimp4python

    " events
    autocmd FileChangedRO * nested call P4EditWithPrompt()
    autocmd BufRead * call <SID>P4InitialBufferVariables()
    autocmd BufRead * call <SID>P4FstatVars()

    " Keyboard shortcuts - default <Leader> is \
    map <silent> <Leader>add :call P4Add()<CR>
    map <silent> <Leader>c :call P4PendingChanges()<CR>
    map <silent> <Leader>d :call P4Diff()<CR>
    map <silent> <Leader>e :call P4Edit()<CR>
    map <silent> <Leader>f :call P4Fstat()<CR>
    map <silent> <Leader>h :call P4Changes()<CR>
    map <silent> <Leader>i :call P4Info()<CR>
    map <silent> <Leader>k :call P4Lock()<CR>
    map <silent> <Leader>l :call P4Filelog()<CR>
    map <silent> <Leader>m :call P4ReopenChange()<CR>
    map <silent> <Leader>n :call P4NewChange()<CR>
    map <silent> <Leader>o :call P4Opened()<CR>
    map <silent> <Leader>r :call P4Revert()<CR>
    map <silent> <Leader>s :call P4Sync()<CR>
    map <silent> <Leader>u :call P4Unlock()<CR>
    map <silent> <Leader>w :call P4Where()<CR>
    map <silent> <Leader>x :call P4Delete()<CR>
    map <silent> <Leader>z :call P4Run()<CR>

    " menus
    menu <silent> &Perforce.p4\ &info                       :call P4Info()<CR>
    menu <silent> &Perforce.p4\ \<command\>                 :call P4Run()<CR>
    menu <silent> &Perforce.-Sep1-                          :
    menu <silent> &Perforce.p4\ s&ync                       :call P4Sync()<CR>
    menu <silent> &Perforce.p4\ &add                        :call P4Add()<CR>
    menu <silent> &Perforce.p4\ &edit                       :call P4Edit()<CR>
    menu <silent> &Perforce.p4\ revert                      :call P4Revert()<CR>
    menu <silent> &Perforce.p4\ delete                      :call P4Delete()<CR>
    menu <silent> &Perforce.p4\ &lock                       :call P4Lock()<CR>
    menu <silent> &Perforce.p4\ &unlock                     :call P4Unlock()<CR>
    menu <silent> &Perforce.p4\ di&ff                       :call P4Diff()<CR>
    menu <silent> &Perforce.p4\ diff&2                      :call P4Diff2()<CR>
    menu <silent> &Perforce.File.p4\ &annotate              :call P4Annotate()<CR>
    menu <silent> &Perforce.File.p4\ &fstat                 :call P4Fstat()<CR>
    menu <silent> &Perforce.File.p4\ filelo&g               :call P4Filelog()<CR>
    menu <silent> &Perforce.File.p4\ submit                 :call P4Submit()<CR>
    menu <silent> &Perforce.File.p4\ tag                    :call P4Tag()<CR>
    menu <silent> &Perforce.File.p4\ &where                 :call P4Where()<CR>
    menu <silent> &Perforce.File.p4\ attribute              :call P4Attribute()<CR>
    menu <silent> &Perforce.File.p4\ fstat\ -Oa             :call P4Attributes()<CR>
    menu <silent> &Perforce.File.p4\ changes                :call P4Changes()<CR>
    menu <silent> &Perforce.File.p4\ print                  :call P4Print()<CR>
    menu <silent> &Perforce.File.p4\ shelve                 :call P4Shelve()<CR>
    menu <silent> &Perforce.File.p4\ shelve\ -d             :call P4ShelveRemove()<CR>
    menu <silent> &Perforce.File.p4\ unshelve               :call P4Unshelve()<CR>
    menu <silent> &Perforce.File.p4\ reopen\ -c             :call P4ReopenChange()<CR>
    menu <silent> &Perforce.File.p4\ reopen\ -t             :call P4ReopenType()<CR>
    menu <silent> &Perforce.File.p4\ resolve                :call P4Resolve()<CR>
    menu <silent> &Perforce.File.p4\ resolved               :call P4Resolved()<CR>
    menu <silent> &Perforce.File.p4\ sizes -a               :call P4Sizes()<CR>
    menu <silent> &Perforce.File.p4\ verify                 :call P4Verify()<CR>
    menu <silent> &Perforce.-Sep2-                          :
    menu <silent> &Perforce.p4\ change\ \(new\)             :call P4NewChange()<CR>
    menu <silent> &Perforce.p4\ changes\ -s\ pending        :call P4PendingChanges()<CR>
    menu <silent> &Perforce.p4\ describe                    :call P4Change()<CR>
    menu <silent> &Perforce.p4\ opened                      :call P4Opened()<CR>
    menu <silent> &Perforce.p4\ clients\ -u\ \<user\>       :call P4Clients()<CR>
    menu <silent> &Perforce.p4\ branches\ -u\ \<user\>      :call P4Branches()<CR>
    menu <silent> &Perforce.Admin.p4\ counters              :call P4Counters()<CR>
    menu <silent> &Perforce.Admin.p4\ lockstat              :call P4Lockstat()<CR>
    menu <silent> &Perforce.Admin.p4\ dbschema              :call P4Dbschema()<CR>
    menu <silent> &Perforce.Admin.p4\ bdstat                :call P4Dbstat()<CR>
    menu <silent> &Perforce.Admin.p4\ depots                :call P4Depots()<CR>
    menu <silent> &Perforce.Admin.p4\ jobspec               :call P4Jobspec()<CR>
    menu <silent> &Perforce.Admin.p4\ license               :call P4License()<CR>
    menu <silent> &Perforce.Admin.p4\ logstat               :call P4Logstat()<CR>
    menu <silent> &Perforce.Admin.p4\ logtail               :call P4Logtail()<CR>
    menu <silent> &Perforce.Admin.p4\ monitor               :call P4Monitor()<CR>
    menu <silent> &Perforce.Admin.p4\ obliterate\ (preview) :call P4Obliterate()<CR>
    menu <silent> &Perforce.Admin.p4\ protect               :call P4Protect()<CR>
    menu <silent> &Perforce.Admin.p4\ triggers              :call P4Triggers()<CR>
    menu <silent> &Perforce.Admin.p4\ tunables              :call P4Tunables()<CR>
    menu <silent> &Perforce.Admin.p4\ typemap               :call P4Typemap()<CR>
    menu <silent> &Perforce.Branching.p4\ branch            :call P4Branch()<CR>
    menu <silent> &Perforce.Branching.p4\ integrated        :call P4Integrated()<CR>
    menu <silent> &Perforce.Branching.Show\ Rev\ Graph      :call P4RevGraph()<CR>
    menu <silent> &Perforce.Jobs.p4\ fix                    :call P4Fix()<CR>
    menu <silent> &Perforce.Jobs.p4\ fixes                  :call P4Fixes()<CR>
    menu <silent> &Perforce.Jobs.p4\ job                    :call P4Job()<CR>
    menu <silent> &Perforce.Jobs.p4\ jobs                   :call P4Jobs()<CR>
    menu <silent> &Perforce.Labels.p4\ label                :call P4Label()<CR>
    menu <silent> &Perforce.Labels.p4\ labels               :call P4Labels()<CR>
    menu <silent> &Perforce.Other.p4\ set                   :call P4Set()<CR>
    menu <silent> &Perforce.Other.p4\ grep                  :call P4Grep()<CR>
    menu <silent> &Perforce.Other.p4\ help                  :call P4Help()<CR>
    menu <silent> &Perforce.User.p4\ group                  :call P4Group()<CR>
    menu <silent> &Perforce.User.p4\ groups\ -u\ \<user\>   :call P4Groups()<CR>
    menu <silent> &Perforce.User.p4\ protects               :call P4Protects()<CR>
    menu <silent> &Perforce.User.p4\ tickets                :call P4Tickets()<CR>
    menu <silent> &Perforce.User.p4\ user                   :call P4User()<CR>
    menu <silent> &Perforce.User.p4\ users                  :call P4Users()<CR>
    menu <silent> &Perforce.Workspace.p4\ client            :call P4Client()<CR>
augroup END

"
" initialize status variables
"
function s:P4InitialBufferVariables()
    let b:headrev=""
    let b:headtype=""
    let b:depotfile=""
    let b:haverev=""
    let b:action=""
    let b:changelist=""
endfunction

"
" init ruler for status messages
"
if( strlen( &rulerformat ) == 0 ) && ( P4SetRuler == 1 )
    set rulerformat=%60(%=%{P4RulerStatus()}\ %4l,%-3c\ %3p%%%)
endif

"
" filelog
"
function P4Filelog()
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("filelog", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print m['depotFile']
        print "{0:<5}{1:<10}{2:<15}{3:<20}{4:<12}description".format('rev','change','action','user','date')
        for i in range(len(m['rev'])):
            timeobj = datetime.fromtimestamp(float(m['time'][i]))
            timestr = timeobj.strftime('%Y/%m/%d')
            print "{0:<5}{1:<10}{2:<15}{3:<20}{4:<12}{5}".format(m['rev'][i],m['change'][i],m['action'][i],m['user'][i],timestr,m['desc'][i])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" Produce string for ruler output
"
function P4RulerStatus()
    if !exists( "b:headrev" )
        call s:P4InitialBufferVariables()
    endif
    if b:action == ""
        if b:headrev == ""
            return ""
        else
            return "[P4: " . b:haverev . "/" . b:headrev . " (" . b:headtype . ")]"
        endif
    else
        return "[P4: " . b:action . " (". b:changelist . ")]"
    endif
endfunction

"
" fstat for ruler
"
function s:P4FstatVars()

    if g:perforceNoInitialFstat != 0
        return
    endif

    let fullPathName = expand('%:p')

python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("fstat", vim.eval('fullPathName'))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        change = ""
        if 'change' in m:
            change = m['change']
        action = ""
        if 'action' in m:
            action = m['action']
        headRev = ""
        if 'headRev' in m:
            headRev = m['headRev']
        headType = ""
        if 'headType' in m:
            headType = m['headType']
        haveRev = ""
        if 'haveRev' in m:
            haveRev = m['haveRev']
        depotFile = ""
        if 'depotFile' in m:
            depotFile = m['depotFile']
        vim.command("let b:headrev = \"%s\"" % headRev)
        vim.command("let b:headtype = \"%s\"" % headType)
        vim.command("let b:changelist = \"%s\"" % change)
        vim.command("let b:depotfile = \"%s\"" % depotFile)
        vim.command("let b:haverev = \"%s\"" % haveRev)
        vim.command("let b:action = \"%s\"" % action)
    p4.disconnect()

except P4Exception:
    """ Let's assume that if fstat fails the file is not in perforce.
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
    """
EOF
endfunction

"
" fstat
"
function P4Fstat()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("fstat", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        change = ""
        if 'change' in m:
            change = m['change']
        action = ""
        if 'action' in m:
            action = m['action']
        headRev = ""
        if 'headRev' in m:
            headRev = m['headRev']
        headType = ""
        if 'headType' in m:
            headType = m['headType']
        haveRev = ""
        if 'haveRev' in m:
            haveRev = m['haveRev']
        depotFile = ""
        if 'depotFile' in m:
            depotFile = m['depotFile']
        print "{0}: {1}/{2} ({3})".format(depotFile,haveRev,headRev,headType)
        if change != "":
            print "Opened in {0} ({1})".format(change,action)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" open for edit with prompt
"
function P4EditWithPrompt()
    if (b:action != "" || b:headrev != "")   " Only do this if file is in perforce
        let confirmation = confirm("p4 edit file first?" ,"&Yes\n&No", 1, "Perforce")
        if confirmation == 1
            call P4Edit()
        endif
    endif
endfunction

"
" open for edit
"
function P4Edit()
    if b:headrev != b:haverev
        let confirmation = confirm("p4 sync file to head revision first?", "&Yes\n&No", 1, "Perforce")
        if confirmation == 1
            call P4Sync()
        endif
    endif
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("edit", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" revert
"
function P4Revert()
    let confirmation = confirm("Revert this file and discard any changes?", "&Yes\n&No", 2, "Perforce")
    if confirmation == 1
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("revert", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("edit!")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    endif
    call s:P4FstatVars()
endfunction

"
" open for add
"
function P4Add()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("add", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" open for delete
"
function P4Delete()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("delete", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    print "File opened for delete and removed from workspace - Vim buffer no longer valid"

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" submit a single file
"
function P4Submit()
    let desc = inputdialog("Enter changelist description", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("submit", "-d", vim.eval("desc"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" sync to head
"
function P4Sync()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("sync", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" annotate
"
function P4Annotate()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("annotate", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" list branches owned by current user
"
function P4Branches()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("info")
    username = info[0]['userName']
    out = p4.run("branches", "-u", username)
    if not (isinstance(out, types.NoneType)):
        print vimp4_FormatTable(['branch', 'description'], out)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" connection info
"
function P4Info()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("info")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display branch mapping
"
function P4Branch()
    let branch = inputdialog("Enter branch name", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("branch", "-o", vim.eval("branch"))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print m['Branch']
        print m['Description']
        for s in m['View']:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" create a new changelist
"
function P4NewChange()
    let description = inputdialog("Enter changelist description", "")
python << EOF
import vim, P4
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    change = p4.fetch_change()
    change['Description'] = vim.eval("description")
    out = p4.save_change(change);
    for s in out:
        print s
    for file in change['Files']:
        print file
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display changelist info
"
function P4Change()
    let change = inputdialog("Enter changelist number", "")
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("describe", "-s", vim.eval("change"))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        timeobj = datetime.fromtimestamp(float(m['time']))
        timestr = timeobj.strftime('%Y/%m/%d')
        print "Change {0} on {1} by {2} ({3})".format(m['change'],timestr,m['user'],m['status'])
        print m['desc']

        revs= m['rev']
        actions = m['action']
        depotFiles = m['depotFile']
        keys = ['action', 'depotFile', 'rev']
        files = []
        for i in range(len(depotFiles)):
            files.append(dict(zip(keys, [actions[i], depotFiles[i], revs[i]])))
        print vimp4_FormatTable(keys, files)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display changelists for current file
"
function P4Changes()
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("changes", "-i", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        print "{0:<10}{1:<15}{2:<25}{3}".format('change','date','user','description')
        for m in out:
            timeobj = datetime.fromtimestamp(float(m['time']))
            timestr = timeobj.strftime('%Y/%m/%d')
            print "{0:<10}{1:<15}{2:<25}{3}".format(m['change'],timestr,m['user'],m['desc'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display changelists for current file
"
function P4PendingChanges()
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("info")
    client = info[0]['clientName']
    username = info[0]['userName']
    out = p4.run("changes", "-u", username, "-c", client, "-s", "pending", "-L")
    for element in out:
        element['desc'] = element['desc'].strip();
    print vimp4_FormatTable(['change', 'desc'], out, sortBy='change')
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display workspace data
"
function P4Client()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("client", "-o")
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print "Client      : %s" % m['Client']
        print "Root        : %s" % m['Root']
        print "Options     : {0}, {1}".format(m['Options'],m['SubmitOptions'])
        print "Line endings: %s" % m['LineEnd']
        print m['Description']
        for s in m['View']:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" list workspaces owned by current user
"
function P4Clients()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("info")
    username = info[0]['userName']
    out = p4.run("clients", "-u", username)
    if not (isinstance(out, types.NoneType)):
        print "{0:<25}description".format('client')
        for m in out:
            print "{0:<25}{1}".format(m['client'],m['Description'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" counters
"
function P4Counters()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("counters")
    if not (isinstance(out, types.NoneType)):
        print "{0:<20}{1:<20}".format("counter","value")
        for m in out:
            print "{0:<20}{1:<20}".format(m['counter'],m['value'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" database schema
"
function P4Dbschema()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("dbschema")
    if not (isinstance(out, types.NoneType)):
        print "{0:<20}{1:<20}".format("table","version")
        for m in out:
            print "{0:<20}{1:<20}".format(m['table'],m['version'])
            print "{0:<5}{1:<20}{2:<15}{3:<15}{4:<15}".format('','name','type','dmtype','fmtkind')
            for i in range(len(m['name'])):
                print "{0:<5}{1:<20}{2:<15}{3:<15}{4:<15}".format('',m['name'][i],m['type'][i],m['dmtype'][i],m['fmtkind'][i])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" database stats
"
function P4Depots()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("depots")
    if not (isinstance(out, types.NoneType)):
        print "{0:<20}{1:<10}{2:<20}{3}".format("depot","type","map","description")
        for m in out:
            print "{0:<20}{1:<10}{2:<20}{3}".format(m['name'],m['type'],m['map'],m['desc'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" depot list
"
function P4Dbstat()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("dbstat","-a")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    out = p4.run("dbstat","-s")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" diff
"
function P4Diff()
    if (exists('b:perforceDiffShowing') && b:perforceDiffShowing != 0)
        if (exists('b:perforceDiffSourceBuffer'))
            let switchTo = bufwinnr(b:perforceDiffSourceBuffer)
            if (switchTo != -1)
                exe switchTo . ' wincmd w'
            endif
        endif
        let otherBufferNr = bufwinnr(b:perforceDiffBuffer)
        let b:perforceDiffShowing = 0
        let b:perforceDiffBuffer = ''
        set nodiff
        set noscrollbind
        set nocursorbind
        set scrollopt-=hor
        set foldmethod=manual
        set foldcolumn=0
        set nofoldenable
        if (otherBufferNr != -1)
            " switch to the other window and close it
            exe otherBufferNr . ' wincmd w'
            wincmd c
            return
        endif
    endif

    " first, let's find the revision we have
    let filename = bufname("%")
    let currentHaveRev = 0
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("fstat", vim.eval("filename"))[0]
    if 'haveRev' in info:
        vim.command("let currentHaveRev=%s" % info['haveRev'])
    p4.disconnect()
except P4Exception:
    """
    Let's just ignore this
    """
EOF
    if (currentHaveRev == 0)
        echo "File not in perforce or there was an error obtaining file information."
        return
    end

    let revision = filename . '#' . currentHaveRev
    let newBufName = filename . "\\#" . currentHaveRev
    echo revision
    let _ts = &tabstop
    let _ft = &filetype
    let _fenc = &fileencoding
    let sourceWindow = bufwinnr('%')
    let b:perforceDiffShowing = 1
    let b:perforceDiffBuffer = revision
    diffthis

    vnew
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    exe 'setlocal tabstop=' . _ts
    exe 'setlocal filetype=' . _ft
    exe 'setlocal fileencoding=' . _fenc
    silent! exe 'file ' . newBufName
python << EOF
import vim, P4, types, re
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("print", "-q", vim.eval("revision"))
    if not (isinstance(out, types.NoneType)):
        lines = "".join(out).split('\n')
        for line in lines:
            vim.current.buffer.append(line)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF

    " Get rid of that stupid first line
    execute '1 delete _'
    " and apparently we are just putting out one extra line... dunno why
    execute '$ delete _'

    setlocal nomodifiable
    let b:perforceDiffShowing = 1
    let b:perforceDiffSourceBuffer = filename
    diffthis
    wincmd w
endfunction

"
" diff2
"
function P4Diff2()
    let rev = inputdialog("Enter revision to diff against head", "")
    if rev == ""
        return
    endif

    " Open diff output on a new scratch window
    botright new
    let filename = bufname("%")
    let ts = &tabstop
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    let tabstop=ts

python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("diff2", vim.eval("filename") + "#" + vim.eval("rev"), vim.eval("filename") + "#head")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            vim.current.buffer.append(s)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF

    " Get rid of that stupid first line
    execute '1 delete _'
    setlocal nomodifiable
    silent file [Diff]
endfunction

"
" fix job
"
function P4Fix()
    let change = inputdialog("Enter changelist number", "")
    let job = inputdialog("Enter job ID", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("fix", "-c", vim.eval("change"), vim.eval("job"))
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" fixes for job
"
function P4Fixes()
    let job = inputdialog("Enter job ID", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("fixes", "-j", vim.eval("job"))
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" where
"
function P4Where()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("where", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print "{0:<15}{1}".format("Depot path",m['depotFile'])
        print "{0:<15}{1}".format("Client path",m['clientFile'])
        print "{0:<15}{1}".format("Local path",m['path'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" command help
"
function P4Help()
    let topic = inputdialog("Help on?", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("help", vim.eval("topic"))
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" verify
"
function P4Verify()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("verify", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        print "{0:<5}{1:<15}{2:<10}{3:<12}{4:<15}{5}".format('rev','action','change','type','status','depot path')
        for m in out:
            status = 'OK'
            if 'status' in m:
                status = m['status']
            print "{0:<5}{1:<15}{2:<10}{3:<12}{4:<15}{5}".format(m['rev'],m['action'],m['change'],m['type'],status,m['depotFile'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display user data
"
function P4User()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("user", "-o")
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print "user        : %s" % m['User']
        print "Email       : %s" % m['Email']
        print "FullName    : {0}".format(m['FullName'])
        if 'JobView' in m:
            print "JobView     : {0}".format(m['JobView'])
        if 'Reviews' in m:
            print "Reviews     :"
            for s in m['Reviews']:
                print "    %s" % s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display user list
"
function P4Users()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("users")
    if not (isinstance(out, types.NoneType)):
        print "{0:<20}{1:<30}{2}".format('User','Email','Name')
        for m in out:
            print "{0:<20}{1:<30}{2}".format(m['User'],m['Email'],m['FullName'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" lock
"
function P4Lock()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("lock", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" unlock
"
function P4Unlock()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("unlock", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" print
"
function P4Print()
    let rev = inputdialog("Enter revision to print", "")
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("print", "-q", vim.current.buffer.name + "#" + vim.eval("rev"))
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" opened files
"
function P4Opened()
python << EOF
import sys, P4, types
p4 = P4.P4()
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("info")
    username = info[0]['userName']
    client = info[0]['clientName']
    out = p4.run("opened", "-u", username, "-C", client)
    if not (isinstance(out, types.NoneType)):
        print vimp4_FormatTable(['change', 'depotFile','rev','action'], out, sortBy='change')
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display group info
"
function P4Group()
    let group = inputdialog("Enter group name", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("group", "-o", vim.eval("group"))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print m['Group']
        print "{0:<15}{1}".format("MaxResults",m['MaxResults'])
        print "{0:<15}{1}".format("MaxScanRows",m['MaxScanRows'])
        print "{0:<15}{1}".format("MaxLockTime",m['MaxLockTime'])
        print "{0:<15}{1}".format("Timeout",m['Timeout'])
        if 'Subgroups' in m:
            print "{0:<15}".format("Subgroups")
            for s in m['Subgroups']:
                print "{0:<5}{1}".format("",s)
        if 'Users' in m:
            print "{0:<15}".format("Users")
            for s in m['Users']:
                print "{0:<5}{1}".format("",s)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" list groups for current user
"
function P4Groups()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    info = p4.run("info")
    username = info[0]['userName']
    out = p4.run("groups", username)
    if not (isinstance(out, types.NoneType)):
        print vimp4_FormatTable(['group', 'maxResuls', 'maxScanRows', 'maxLockTime', 'timeout'], out)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" grep
"
function P4Grep()
    let pattern = inputdialog("Grep for", "")
    let path = inputdialog("Grep where", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("grep", "-e", vim.eval("pattern"), vim.eval("path"))
    if not (isinstance(out, types.NoneType)):
        print "{0:<40}{1:<10}{2}".format('depotFile','rev','matchedLine')
        for m in out:
            print "{0:<40}{1:<10}{2}".format(m['depotFile'],m['rev'],m['matchedLine'].replace("\t","    "))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" integrated
"
function P4Integrated()
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("integrated", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display job info
"
function P4Job()
    let job = inputdialog("Enter job ID", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("job", "-o", vim.eval("job"))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print m['Job'] + " (" + m['Status'] + ")"
        print "    " + m['Description']
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display job list
"
function P4Jobs()
    let jobview = inputdialog("Enter job query", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("jobs", "-e", vim.eval("jobview"))
    if not (isinstance(out, types.NoneType)):
        for m in out:
            print m['Job'] + " (" + m['Status'] + ")    " + m['Description']
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" job spec
"
function P4Jobspec()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("jobspec", "-o")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display label info
"
function P4Label()
    let label = inputdialog("Enter label name", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("label", "-o", vim.eval("label"))
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print m['Label'] + " (" + m['Options'] + ")"
        if 'Revision' in m:
            print "Revision: %s" % m['Revision']
        print "  " + m['Description']
        for s in m['View']:
            print "    " + s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display label list
"
function P4Labels()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("labels", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        print vimp4_FormatTable(['label', 'Options', 'Description'], out);
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" environment info
"
function P4Set()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    print p4.identify()
    env_vars = ["P4AUDIT","P4CHARSET","P4COMMANDCHARSET","P4CLIENT","P4CONFIG","P4DEBUG","P4DESCRIPTION","P4DIFF","P4DIFFUNICODE","P4EDITOR","P4HOST","P4JOURNAL","P4LANGUAGE","P4LOG","P4MERGE","P4MERGEUNICODE","P4NAME","P4PAGER","P4PASSWD","P4PORT","P4TARGET","P4TICKETS","P4USER","P4ZEROCONF","PWD","TMP","TEMP"]
    for e in env_vars:
        print("{0:<4}{1:<20}{2}".format("",e,p4.env(e)))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" sizes
"
function P4Sizes()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("sizes", "-a", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        print "{0:<5}{1}".format('rev','fileSize (KB)')
        for m in out:
            fsize = "%.1f" % (float(m['fileSize']) / 1024.0)
            print "{0:<5}{1}".format(m['rev'],fsize)
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" tag a single file
"
function P4Tag()
    let label = inputdialog("Enter label name", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("tag", "-l", vim.eval("label"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" license info
"
function P4License()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("license", "-o")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" db lock info
"
function P4Lockstat()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("lockstat")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" log info
"
function P4Logstat()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("logstat")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" log tail
"
function P4Logtail()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("logtail")
    if not (isinstance(out, types.NoneType)):
        print out[0]['file']
        print out[0]['data'].replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" monitor
"
function P4Monitor()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("monitor", "show")
    if not (isinstance(out, types.NoneType)):
        print("{0:<10}{1:<10}{2:<20}{3:<15}{4}".format('id','status','user','time','command'))
        for m in out:
            print("{0:<10}{1:<10}{2:<20}{3:<15}{4}".format(m['id'],m['status'],m['user'],m['time'],m['command']))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" obliterate
"
function P4Obliterate()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("obliterate", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        print("PREVIEW MODE")
        for m in out:
            if 'clientRecDeleted' in m:
                print("{0:<5}{1}".format(m['clientRecDeleted'], "client records deleted"))
            if 'labelRecDeleted' in m:
                print("{0:<5}{1}".format(m['labelRecDeleted'], "label records deleted"))
            if 'integrationRecDeleted' in m:
                print("{0:<5}{1}".format(m['integrationRecDeleted'], "integration records deleted"))
            if 'workingRecDeleted' in m:
                print("{0:<5}{1}".format(m['workingRecDeleted'], "working records deleted"))
            if 'revisionRecDeleted' in m:
                print("{0:<5}{1}".format(m['revisionRecDeleted'], "revision records deleted"))
            if 'purgeFile' in m:
                print('Purged ' + m['purgeFile'] + '#' +  m['purgeRev'])
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" display protetions data
"
function P4Protects()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("protects")
    if not (isinstance(out, types.NoneType)):
        print("{0:<15}{1:<20}{2:<20}{3}".format('Permission','User or group','Host','Path'))
        for m in out:
            who = ''
            if 'user' in m:
                who = m['user']
            if 'group' in m:
                who = m['group']
            print("{0:<15}{1:<20}{2:<20}{3}".format(m['perm'],who,m['host'],m['depotFile']))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" protections table
"
function P4Protect()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("protect", "-o")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" reopen to changelist
"
function P4ReopenChange()
    let change = inputdialog("Enter changelist number", "")
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("reopen", "-c", vim.eval("change"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" reopen file type
"
function P4ReopenType()
    let type = inputdialog("Enter file type", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("reopen", "-t", vim.eval("type"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" resolve
"
function P4Resolve()
    let accept = inputdialog("Enter accept resolve option:\n-as = safe, -am = merge, -at = source (theirs), -ay target (yours), -af = force", "")
python << EOF
import vim, P4, types
accept = vim.eval("accept")
if accept == '-am' or accept == '-af' or accept == '-as' or accept == '-at' or accept == '-ay':
    p4 = P4.P4()
    p4.prog = "VIM Integration"
    P4Exception = P4.P4Exception
    try:
        p4.connect()
        p4.tagged = False
        out = p4.run("resolve", accept, vim.current.buffer.name)
        if not (isinstance(out, types.NoneType)):
            for s in out:
                print s.replace("\t","    ")
        p4.disconnect()
        vim.command("silent! edit")

    except P4Exception:
        for e in p4.errors:
            print e
        for w in p4.warnings:
            print w
else:
    print("Error: you must select one of -am/-af/-as/-at/-ay")
EOF
    call s:P4FstatVars()
endfunction

"
" resolve status
"
function P4Resolved()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("resolved", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print("{0:<40}{1:<15}{2}{3},{4}".format(m['toFile'],m['how'],m['fromFile'],m['startFromRev'],m['endFromRev']))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" trigger table
"
function P4Triggers()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("triggers", "-o")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" typemap table
"
function P4Typemap()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("typemap", "-o")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" tickets
"
function P4Tickets()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("tickets")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" tunables
"
function P4Tunables()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("tunables", "-a")
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" set attribute
"
function P4Attribute()
    let attrib = inputdialog("Attribute name", "")
    let value = inputdialog("Enter value", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("attribute", "-n", vim.eval("attrib"), "-v", vim.eval("value"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s.replace("\t","    ")
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" attribute list
"
function P4Attributes()
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("fstat", "-Oa", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        m = out[0]
        print("{0:<30}{1}".format("Name","Value"))
        for key in iter(m):
            if key.find("attr-") == 0:
                print("{0:<30}{1}".format(key[5:],m[key]))
            if key.find("openattr-") == 0:
                print("{0:<30}{1}".format(key[9:],m[key]))
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" run any command
"
function P4Run()
    let cmd = inputdialog("Enter complete command to run, without the leading 'p4'", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run(vim.eval("cmd").split())
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" shelve
"
function P4Shelve()
    let change = inputdialog("Enter changelist number", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("reopen", "-c", vim.eval("change"), vim.current.buffer.name)
    out = p4.run("shelve", "-c", vim.eval("change"), "-f", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" remove from shelf
"
function P4ShelveRemove()
    let change = inputdialog("Enter changelist number", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("shelve", "-d", "-c", vim.eval("change"), "-f", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
endfunction

"
" unshelve
"
function P4Unshelve()
    let change = inputdialog("Enter changelist number", "")
python << EOF
import vim, P4, types
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = False
    out = p4.run("unshelve", "-s", vim.eval("change"), vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        for s in out:
            print s
    p4.disconnect()
    vim.command("silent! edit")

except P4Exception:
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
    call s:P4FstatVars()
endfunction

"
" ASCII rev graph
"
function P4RevGraph()
python << EOF
import vim, P4, types
from datetime import datetime
p4 = P4.P4()
p4.prog = "VIM Integration"
P4Exception = P4.P4Exception
try:
    p4.connect()
    p4.tagged = True
    out = p4.run("integrated", vim.current.buffer.name)
    if not (isinstance(out, types.NoneType)):
        graph = ''
        for m in out:
            # current file always listed as 'to file'
            how = m['how']
            if how.find("into") != -1 or how.find("ignored by") != -1:
                toFile = m['fromFile']
                fromFile = m['toFile']
                startToRev = m['startFromRev']
                endToRev = m['endFromRev']
                startFromRev = m['startToRev']
                endFromRev = m['endToRev']
            else:
                toFile = m['toFile']
                fromFile = m['fromFile']
                startToRev = m['startToRev']
                endToRev = m['endToRev']
                startFromRev = m['startFromRev']
                endFromRev = m['endFromRev']
            change = m['change']
            graph = graph + fromFile + endFromRev + '@' + toFile + endToRev + '@change ' + change + ' ' + how + "|"
        if graph == '':
            graph = 'NONE'
        vim.command("let b:graph = \"%s\"" % graph)
    else:
        print("No integration records")
        vim.command("let b:graph = \"NONE\"")
    p4.disconnect()

except P4Exception:
    vim.command("let b:graph = \"NONE\"")
    for e in p4.errors:
        print e
    for w in p4.warnings:
        print w
EOF
perl << EOF
use Graph::Easy;
my @gstr = VIM::Eval('b:graph');
if($gstr[1] ne '' and $gstr[1] ne 'NONE') {
    my @parts = split(/\|/, $gstr[1]);
    my $graph = Graph::Easy->new();
    foreach my $pair (@parts) {
        my @p = split(/@/,$pair);
        $graph->add_node($p[0]);
        $graph->add_node($p[1]);
        $graph->add_edge($p[0],$p[1],$p[2]);
    }
    VIM::Msg($graph->as_ascii());
}
EOF
endfunction

" vim: ts=4:sw=4:tw=100:et:


