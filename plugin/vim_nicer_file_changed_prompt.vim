" Streamline behavior when file is modified externally.
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-nicer-file-changed-shell
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2020 Landon Bouma.

" ########################################################################

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand("%:p") ==# expand("<sfile>:p")
  unlet g:loaded_nicer_file_changed_prompt
endif

if exists("g:loaded_nicer_file_changed_prompt") || &cp

  finish
endif

let g:loaded_nicer_file_changed_prompt = 1

" ########################################################################

" This plugin makes two changes to the FileChangedShell prompt behavior:
"
" 1. The default selected button is 'Load File', so you can just press
"    Return (or Space) to reload the file, which is usually the action
"    you want. (And it's easy to undo — Press Ctrl-z and the changes
"    are undone).
"
" 2. The prompt is not shown for certain types of changes that you
"    shouldn't care about, like permissions changes.

" (lb): I made this plugin because I rebase source code often, and I
" found myself needing to press Tab to switch the prompt button from
" 'OK' to 'Load File'. And you know me, always reducing repetition.

" ########################################################################

" How it works
" ------------
"
" - Intercept the file changed event, and only prompt the user for specific
"   events, such as file modified, but automatically reload the file and do
"   not prompt for other events, such as permissions or timestamp changed.
"
"   If the file was modified, use a confirm() dialog like Vim would normally
"   do when a file is modified externally. Use the return value to set
"   v:fcs_choice to tell Vim whether to reload the file or not, depending on
"   what option the user chose.
"
"   But unlike the default Vim behavior, set the "Load File" button as the
"   dialog default. The user will still have to acknowledge that a file was
"   externally modified, but they can just press Enter to reload the file
"   (and they don't have to press Tab or use the mouse to do so). This is
"   assuming that most of the time, you want to reload the file if it was
"   modified externally, because you were probably the one who modified it,
"   which is why you've installed this plugin.

" Caveat
" ------
"
"   - There's a hack herein: When Vim reloads the modified file, it does
"     not seem to trigger the buffer or file event handlers, and the file
"     settings are not restored properly.
"
"     To fix this, the code uses a timer to help reload the file properly.
"
"     - (lb): Specifically, the `tabstop` setting was changed, and it was
"       not reset according to any Vim modeline or `.editorconfig` file
"       (which the dubs_style_guard BufEnter and BufRead handlers do).
"
"     - Note that the FileChangedShell event handler code is not allowed
"       to actually change the buffer. I.e., that event handler cannot
"       call `:edit` to reload the buffer, or to otherwise trigger the
"       BufEnter or BufRead events.
"
"       As a hack, the code sets a timer to run a bit after the event
"       handler. The timer function switches to the window with the buffer
"       that changed and reloads it. Very much a hack, but, hey, welcome to
"       How I Vim!
"
"     - Note that the issue happens when we set v:fcs_choice = "reload"
"       and do not display the dialog. If we go ahead with the dialog,
"       and change the default dialog choice to be "Load File", the
"       tabstop issue does not happen. But the whole point of this is
"       to avoid being prompted for reload *every single file* in a
"       project after rebasing. And you should be encouraged to rebase,
"       not discouraged. Rebase early, Rebase often, 'smy motto.

" Ref.
" ----
"
" - Inline:
"
"   :h FileChangedShell
"
"   :h fcs_choice
"
" - Online:
"
"   https://vim.fandom.com/wiki/File_no_longer_available_-_mark_buffer_modified

" ########################################################################

function! s:file_changed_event_should_ask()
  let l:should_ask = 0

  let aname = expand("<afile>:p")
  let msg = 'File "' . l:aname . '"'
  if v:fcs_reason == "deleted"
    let msg .= " no longer available - maybe set 'modified'?"
    " The tip sets modified... should we really?
    "  call setbufvar(expand(l:aname), '&modified', '1')
    echohl WarningMsg
  elseif v:fcs_reason == "time"
    " This is what git rebase causes.
    let msg .= " timestamp changed"
    " Tell caller not to prompt, but to automatically reload.
    let l:should_ask = -1
  elseif v:fcs_reason == "mode"
    let msg .= " permissions changed"
    " Tell caller not to prompt, but to automatically reload.
    let l:should_ask = -1
  elseif v:fcs_reason == "changed"
    let msg .= " contents changed"
    let l:should_ask = 1
  elseif v:fcs_reason == "conflict"
    let msg .= " CONFLICT --"
    let msg .= " is modified, but"
    let msg .= " was changed outside Vim"
    let l:should_ask = 1
    echohl ErrorMsg
  else  " unknown values (future Vim versions?)
    let msg .= " FileChangedShell reason="
    let msg .= v:fcs_reason
    let l:should_ask = 1
    echohl ErrorMsg
  endif

  redraw!
  echomsg msg
  echohl None

  return l:should_ask
endfunction

" ***

let s:reload_bufnrs = []

function! s:file_changed_event_handle()
  " Eliminate unnecessary prompting, e.g., if timestamp changed, but not content.
  let l:should_ask = s:file_changed_event_should_ask()

  " If the "file changed" reason is timestamp changed, automatically reload.
  if l:should_ask < 0
    let v:fcs_choice = "reload"
    " echom "Auto-reloading: " . expand("<afile>:p")

    " Note that we cannot change the buffer during FileChangedShell callback.
    " - E.g., calling edit:
    "     execute "edit " . expand("<afile>:p")
    "   will provoke the response:
    "     E811: Not allowed to change buffer information now
    " - However, that doesn't mean we can't use a hack: Set
    "   a callback to reload the buffer, hopefully (250 msec)
    "   after Vim finishes the event.
    " - SOFAR/SOGOOD/2020-09-24: (lb): I added this code on 2020-07-02. So
    "   far, it's been working fine, even the 250 msec. value I guessed at.
    call add(s:reload_bufnrs, bufnr(expand("<afile>:p")))
    let l:timer = timer_start(250, 'FileChangeApresReload')
  else
    call s:file_changed_event_prompt()
  endif
endfunction

" ***

function! FileChangeApresReload(timer)
  if s:ActiveWindowIsProjectTray()
    " See note above ActiveWindowIsProjectTray: Don't run `bufdo` from
    " the project tray window.
    " - Note that the user cannot close all but the project tray. If the only
    "   two windows open are the project tray and a file, and the user tries
    "   to close the file window, it'll close the project tray window instead.
    "   - So if the project tray is open, there's always another window open.
    "     (Also, the project tray window is always the first window, 1.)
    execute (winnr() + 1) .. "wincmd  w"
  endif

  let l:curbuf = bufnr()

  " echom "FileChangeApresReload: Reload count: " . len(s:reload_bufnrs)
  for l:bufnum in s:reload_bufnrs
    execute l:bufnum . "bufdo edit"

    " Don't call `bufdo` twice on the same buffer.
    if l:curbuf == l:bufnum
      let l:curbuf = -1
    endif
  endfor
  let s:reload_bufnrs = []

  if l:curbuf != -1
    execute l:curbuf . "bufdo edit"
  endif
endfunction

" ***

" This works around an issue calling `bufdo edit` from the project tray.
" REFER:
"   https://github.com/landonb/dubs_project
" UCASE: Consider the user has a file open and rebases the repo wherein it
" lives, causing file changes, but the file returns to the state it was last
" in — So Vim will prompt about changes, but we don't want to annoy the user.
" During the rebase, the user had their terminal in the foreground, and after
" the rebase, the user clicks back to Vim. If the user clicks the project tray,
" the `bufdo edit` call causes Vim to load a different buffer into the project
" tray window, even though the buffer number is not the project tray buffer.
" (And if you call `bufdo edit` on the project tray buffer, Vim retorts,
" 'E32: No file name'.) So check if the current window is the project tray,
" and change windows if that's the case.
" - BWARE: Vim won't update the title bar until the user does something, i.e.,
"   the titlebar will show the project tray filename (e.g., `.vimprojects`)
"   until the user moves the cursor, presses Escape, starts editing, etc.
function! s:ActiveWindowIsProjectTray()
  if exists("g:proj_running") && (bufwinnr(g:proj_running) == winnr())
    return 1
  endif

  return 0
endfunction

" ***

" Note that in MacVim, the system dialog sorta works the way we want
" if you dismiss it with a <Space> (but not a <Return>, which does not
" reload the file). But we still want to avoid the prompt for changes
" we don't care about (like permissions).
"
" However, MacVim reverses the button order -- so OK is the #2 button.
"
" But then, for whatever reason, the <Space> and <Return> behavior
" flips, and now <Return> works to "Load File", and <Space> does not.
function! s:file_changed_dialog_prepare()
  if !has('macunix')
    let s:button_index_load =  2
    let s:dialog_loadf_hint = "Press Enter or Space to reload."
  else
    let s:button_index_load =  1
    let s:dialog_loadf_hint = "Press Enter to reload."
  endif
endfunction

call <SID>file_changed_dialog_prepare()

" ***

function! s:file_changed_event_prompt()
  " NOTE: From :h FileChangedShell:
  "   NOTE: When this autocommand is executed, the
  "   current buffer "%" may be different from the
  "   buffer that was changed, which is in "<afile>".
  " - That is, the bufname call you'd normally make is not the one to make:
  "     let l:bufn = bufname("%")  " Not it!
  let l:bufn = expand('<afile>')

  " The Vanilla Vim looks like:
  "   "Warning: File \"" . l:bufn . "\" has changed since editing started\n"
  "   \ . "See \":help W11\" for more info."
  let l:confirmation_msg = "Yo! “" . l:bufn . "” has changed. " . s:dialog_loadf_hint

  " Recreate a dialog similar to what Vim normally uses,
  " - Set the default choice to the second button, "Load File".
  let l:default_load = s:button_index_load
  " - Set the Dialog type: Error, Question, Info, [W]arning, or Generic.
  let l:diaglog_type = "W"
  let l:user_response = confirm(
    \ l:confirmation_msg, "&OK\n&Load File", l:default_load, l:diaglog_type)

  " (lb): The following SU.com article mentions calling `edit`, e.g.,
  "   if l:user_response == s:button_index_load | edit | endif
  " Though some readers suggest calling
  "   edit <afile>
  " Or
  "   execute 'edit' fnameescape(l:bufn)
  " - But we're not allowed to reload the buffer from the FileChangedShell
  "   handler. See comments above. See also: :h fcs_choice.
  " - Ref:
  "     https://superuser.com/questions/731979/how-to-determine-what-buffer-was-changed-externally-with-gvim

  if l:user_response == s:button_index_load
    let v:fcs_choice = "reload"
  else
    let v:fcs_choice = ""
  endif
endfunction

" ########################################################################

function! s:setup_file_changed_prompt_handler()
  augroup NicerFCPGroup
    " Remove! group autocommands.
    autocmd! NicerFCPGroup
    " Setup group autocommands.
    autocmd NicerFCPGroup FileChangedShell * call <SID>file_changed_event_handle()
  augroup END
endfunction

" ########################################################################

call <SID>setup_file_changed_prompt_handler()

" ########################################################################

