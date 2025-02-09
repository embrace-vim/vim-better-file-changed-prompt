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

" -------------------------------------------------------------------

function! g:embrace#fcs_handler#FCSHandler() abort
  " Highlight group for echo.
  let l:echohl = ''
  " For echom messages and confirm().
  let l:msg = ''
  " Internal value, one of: '', 'ask'.
  let l:prompt = ''
  " Caller sets v:fcs_choice if l:prompt != ''
  let l:fcs_choice = 'edit'
  " Some pizazz.
  let l:flare = ''

  " Note that '%' is *not* the current buffer, because cursor might
  " be in a window other than the window with the buffer whose file
  " changed.
  " So use <afile> instead, and avoid b: variables.
  " - There's also <abuf>, which sometimes works with setbufvar, but
  "   sometimes not, failing, e.g., E94: No matching buffer for 1
  "   - So stick with <afile>.
  "   let l:bufnr = expand('<abuf>')
  let l:bname = expand('<afile>:p')

  let l:vim_fcs_prompt_file_deleted = 0

  if v:fcs_reason == "deleted"
    " The Vim Tip marks modified, which forces user to save or force-close.
    " - E.g.,
      "     call setbufvar(expand(l:buffer_name), '&modified', '1')
    " - Let's not, to make life easier. User should see tailored echo msg.
    "
    " If user Alt-Tabs away from GUI and Alt-Tabs back, FileChangedShell
    " fires again if the file is still absent. So we'll at least
    " acknowledge that we're reiterating ourselves.
    if getbufvar(l:bname, 'vim_fcs_prompt_file_deleted', 0)
      let l:echohl = 'DiffDelete'
      " Vim shows message, does not prompt:
      "   E211: File "{filepath}" no longer available
      " Vim alerts if deleted file is recreated, but Neovim doesn't.
      "   let l:prompt = 'ignore'
      let l:msg = 'File deleted!'
    else
      let l:echohl = 'DiffChange'
      let l:msg = 'Still deleted'
    endif
    let l:vim_fcs_prompt_file_deleted = 1
    let l:fcs_choice = ''
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

  if l:vim_fcs_prompt_file_deleted
    call setbufvar(l:bname, 'vim_fcs_prompt_file_deleted', l:vim_fcs_prompt_file_deleted)
  else
    " Ideally we'd unlet, but per comment above, l:bufnr cannot be used.
    " - E.g., 
    "   let l:bufnr = expand('<abuf>')
    "   execute l:bufnr .. 'bufdo unlet! b:vim_fcs_prompt_file_deleted'
    " Produces the error:
    "   E811: Not allowed to change buffer information now
    " So use setbufvar instead.
    call setbufvar(l:bname, 'vim_fcs_prompt_file_deleted', 0)
  endif

  return [l:echohl, l:msg, l:prompt, l:fcs_choice, l:flare]
endfunction

