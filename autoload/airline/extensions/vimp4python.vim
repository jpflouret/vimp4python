let s:spc = g:airline_symbols.space


function! airline#extensions#vimp4python#init(ext)

  call airline#parts#define_raw('p4status', '%{P4RulerStatus()}')

  call a:ext.add_statusline_func('airline#extensions#vimp4python#apply')

endfunction


function! airline#extensions#vimp4python#apply(...)
  if ((exists("b:action") && b:action != "") || (exists("b:headrev") && b:headrev != ""))   " Only do this if file is in perforce
    let w:airline_section_b = '%{P4RulerStatus()}' . s:spc . g:airline_left_alt_sep . s:spc . get(w:, 'airline_section_b', g:airline_section_b)
  endif
endfunction
