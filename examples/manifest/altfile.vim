
if exists('g:loaded_cppaltfile')
  finish
endif
let g:loaded_cppaltfile = 1

function! Fcppaltfile(host)
  if executable('altfile-plugin') != 1
    echoerr "Executable 'altfile-plugin' not found in PATH."
  endif

  let g:job_cppaltfile = jobstart(['altfile-plugin'])

  " make sure the plugin host is ready and double check rpc channel id
  let g:cppaltfile_channel = 0
  for count in range(0, 100)
    if g:cppaltfile_channel != 0
      break
    endif
    sleep 1m
  endfor
  if g:cppaltfile_channel == 0
    echoerr "Failed to initialize cppaltfile"
  endif

  return g:cppaltfile_channel
endfunction

call remote#host#Register('cppaltfile', '*', function('Fcppaltfile'))
call remote#host#RegisterPlugin('cppaltfile', 'cppaltfilePlugin', [
\ {'type': 'function', 'name': 'GoFindAlt', 'sync': 0, 'opts': {}},
\ {'type': 'function', 'name': 'FindAlt', 'sync': 1, 'opts': {}},
\ ])