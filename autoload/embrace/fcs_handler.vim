" vim:tw=0:ts=2:sw=2:et:norl
" Author: Ewfalor
"   https://vim.fandom.com/wiki/File_no_longer_available_-_mark_buffer_modified
" Adapter: Landon Bouma <https://tallybark.com/>
"   Changes Copyright © 2020, 2024 Landon Bouma.
"   - Everything change except the if-elseif-endif conditionals.
"   - To compare against the unmodified source, run:
"     git diff c4addd3..HEAD -- autoload/embrace/file_changed_shell.vim
" Project: https://github.com/embrace-vim/vim-better-file-changed-prompt#🗯
" License: CC BY-SA / Creative Commons Attribution-Share Alike License 3.0 (Unported)
"   https://www.fandom.com/licensing
"   https://creativecommons.org/licenses/by-sa/3.0/
"     vim-better-file-changed-prompt/LICENSE-CC-BY-SA-3.0

" -------------------------------------------------------------------------

function! g:embrace#fcs_handler#FCSHandler() abort
  " Highlight group for echo.
  let l:echohl = ''
  " For echom messages and confirm().
  let l:msg = ''
  " Internal value, one of: '', 'ask'.
  let l:prompt = ''
  " Some pizazz.
  let l:flare = ''

  if v:fcs_reason == "deleted"
    " The Vim Tip marks modified, which forces user to save or force-close.
    " - Let's not, to make life easier. User should see tailored echo msg.
    "  call setbufvar(expand(a:name), '&modified', '1')
    let l:echohl = 'DiffDelete'
    let l:prompt = 'ask'
    let l:msg = 'File deleted!'
    let l:flare = '🐽'
  elseif v:fcs_reason == 'time'
    " This is often what git-rebase will trigger.
    let l:echohl = 'DiffAdd'
    let l:prompt = ''
    let l:msg = 'Timestamp changed'
    let l:flare = '🤹'
  elseif v:fcs_reason == 'mode'
    let l:echohl = 'DiffAdd'
    " MAYBE: Vim *will* prompt when permissions change, so we might
    " want to, as well. Or maybe only if the file becomes unwritable
    " (or unreadable) by the user.
    " - But this is a rare use case the author rarely sees, so not
    "   gonna care until it becomes an issue for me or any users.
    let l:prompt = ''
    let l:msg = 'Permissions changed'
    let l:flare = '💂'
  elseif v:fcs_reason == 'changed'
    " NTRST: If FCS handler returns v:fcs_choice='', buffer doesn't reload,
    " but changes to the file itself such as modeline will take effect!
    let l:echohl = 'DiffChange'
    let l:prompt = 'ask'
    let l:msg = 'File changed!'
    let l:flare = '📠'
  elseif v:fcs_reason == 'conflict'
    " Not really an error, just so the echo is more noticable.
    " MAYBE: Perhaps the default action when *conflicts* should
    " be opposite, to ignore changes?
    let l:echohl = 'ErrorMsg'
    let l:prompt = 'ask'
    let l:msg = 'Conflicts outside Vim!!'
    let l:flare = '💥'
  else
    " Unknown reason (future Vim versions?)
    let l:echohl = 'ErrorMsg'
    let l:prompt = 'ask'
    let l:msg = 'UNKNOWN event: v:fcs_reason=' .. v:fcs_reason
    let l:flare = '🧘'
  endif

  return [l:echohl, l:msg, l:prompt, l:flare]
endfunction

