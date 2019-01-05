
if exists('g:loaded_demoplugin')
  finish
endif
let g:loaded_demoplugin = 1

function! Fdemoplugin(host)
  if executable('demo-plugin') != 1
    echoerr "Executable 'demo-plugin' not found in PATH."
  endif

  let g:job_demoplugin = jobstart(['demo-plugin'])

  " make sure the plugin host is ready and double check rpc channel id
  let g:demoplugin_channel = 0
  for count in range(0, 100)
    if g:demoplugin_channel != 0
      break
    endif
    sleep 1m
  endfor
  if g:demoplugin_channel == 0
    echoerr "Failed to initialize demoplugin"
  endif

  return g:demoplugin_channel
endfunction

call remote#host#Register('demoplugin', '*', function('Fdemoplugin'))
call remote#host#RegisterPlugin('demoplugin', 'demopluginPlugin', [
\ {'type': 'function', 'name': 'Greet', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'SumBeginToEnd', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'SetVarValueSync', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'SetVarValueAsync', 'sync': 0, 'opts': {}},
\ ])