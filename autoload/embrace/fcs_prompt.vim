" vim:tw=0:ts=2:sw=2:et:norl
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-better-file-changed-prompt#🗯
" License: License: CC0 1.0 <https://creativecommons.org/publicdomain/zero/1.0/>
"   Copyright © 2020, 2024 Landon Bouma.

" -------------------------------------------------------------------

" This plugin makes two changes to the FileChangedShell prompt behavior:
"
" - 1.) The default action on <Enter> is changed to Edit (reload
"       buffer), so you can just press Return to reload the file.
"       This is probably the action that you usually want. (The
"       builtin default is Ignore changes.) 
"
"   - And it's easy to undo — Press Ctrl-Z and the changes are undone.
"
"   - Note that pressing <Space> on Linux works, too.
"
"     - But on MacVim, pressing <Space> selects whatever button
"       is selected. And you can move the selection with <Tab>.
"       (Also you cannot <Escape> away from the dialog.)
"
"   - Note if you Ignore changes, some changes take effect.
"
"     - E.g., if you change the modeline from another program,
"       but then Ignore the changes in gvim, the modeline changes
"       are still applied! (This happens immediately in MacVim,
"       or on BufEnter in Linux Mint MATE, even though the buffer
"       itself is not loaded with the changes!)
"
"   - Note on MacVim that <Enter> *always* picks the default
"     action, with is the button with the blue background.
"
"     And <Space> always picks the button with the highlight,
"     which you can move with <Tab>.
"
"     The default MacVim file-changed prompt has five buttons.
"     - [OK] is the default which <Enter> will select, and it
"       ignores the changes.
"     - The last button, [Ignore All], is selected by default,
"       which <Space> will select. You can move the highlight
"       with <Tab>.
"     - [OK] is essentially [Ignore], but only applies to the
"       current file. If more than one buffer had external
"       changes, you'll be prompted for each buffer unless
"       you choose [Load All] or [Ignore All].
"     - Author is not sure what [Load File and Options] does
"       different than [Load File]. They behave the same for
"       me (or I just haven't noticed the difference).
"
"       - REFER: Re: the [Load All] and [Ignore All] buttons,
"         added upstream in 2023 (though was present in
"         MacVim for longer):
"
"           https://groups.google.com/g/vim_dev/c/bbQWl0yr0Kc
"
"         Also this re: [Load File and Options] feature:
"
"           https://github.com/vim/vim/pull/9579
"
"     - Here's a look at the MacVim buttons:
"
"                         [OK]
"                       Load File
"                  Load File and Options
"                       Load All
"                   〖 Ignore All 〗
"
"   - BWARE: This plugin is built for users where external
"     changes rarely happen, or only occasionally happen to
"     a file or two.
"
"     - If in your workflow *lots* of files are changed
"       externally, you might not appreciate that [Load All]
"       and [Ignore All] are excluded.
"
"       Or maybe you should consider :autoread
"
"       (Note author doesn't use :autoread because I
"       sometimes modify a file to how I want to commit
"       it, save, then `git add` it, but forget to then
"       save the Vim buffer before I fixup or otherwise
"       rebase the project. Then Vim tells me the buffer
"       changed, and I can either hit <Enter> to reload
"       and the <Ctrl-Z>, or I can click [Ignore], or I
"       can <Tab> then <Space> to Ignore (on MacVim) or
"       <Alt-I> (on Linux). Basically, I don't want to
"       use :autoread because then I won't be alerted
"       that I need to recover my buffer changes.)
"
" - 2.) This plugin prints a colorful message with a little flare
"       for every event.
"
"    - Vim doesn't alert on timestamp changes, or report anything.
"
"    - Also when user reloads file, Vim just prints the basename
"      and a few file stats in a boring white font.
"
"    - This plugin prints an alternative message is a color
"      befitting of the event, uses the full file path, and
"      tosses in an emoji character to help you grok what
"      just happened more easily.

" -------------------------------------------------------------------

" How it works
" ------------
"
" - Intercept the file changed event, and only prompt the user for specific
"   events, such as file modified, but automatically reload the file and do
"   not prompt for other events, such as permissions or timestamp changed.
"
"   If the file was modified, use a confirm() dialog like Vim would normally
"   do when a file is modified externally. Use the return value to set
"   v:fcs_choice to tell Vim whether to reload (edit) the file or not,
"   depending on what option the user chose.
"
"   But unlike the default Vim behavior, set the "Load File" button as the
"   dialog default. The user will still have to acknowledge that a file was
"   externally modified, but they can just press Enter to reload the file
"   (and they don't have to press Tab or use the mouse to do so). This is
"   assuming that most of the time you'll want to reload the file if it was
"   modified externally, because you were probably the one who modified it,
"   which is why you've installed this plugin.
"
" Ref.
" ----
"
" - Online help:
"
"   :h FileChangedShell
"
"   :h v:fcs_choice
"
"   :h v:fcs_reason
"
" - Vim Tip:
"
"   https://vim.fandom.com/wiki/File_no_longer_available_-_mark_buffer_modified
"
" - REFER: :h timestamp
"
"   'When Vim notices the timestamp of a file has changed, and the file is being
"    edited in a buffer but has not changed, Vim checks if the contents of the file
"    is equal.  This is done by reading the file again (into a hidden buffer, which
"    is immediately deleted again) and comparing the text.  If the text is equal,
"    you will get no warning.

" -------------------------------------------------------------------

" - REFER: 'When this autocommand is executed, the
"   current buffer "%" may be different from the
"   buffer that was changed, which is in "<afile>".'
"     :h FileChangedShell
"   - I.e., not `bufname("%")`.
"   - REFER: And if you want winnr:
"     bufwinnr(0 + expand('<abuf>'))

function! g:embrace#fcs_prompt#FCSPrompt() abort
  " CXREF:
  " ~/.kit/nvim/embrace-vim/start/vim-better-file-changed-prompt/autoload/embrace/fcs_handler.vim
  let [l:echohl, l:msg, l:prompt, l:fcs_choice, l:flare] = g:embrace#fcs_handler#FCSHandler()

  let l:fpath = s:FCSPromptExpandFilePath()

  if l:prompt == ''
    call s:FCSPromptAutoChoose(l:fcs_choice)
  elseif l:prompt == 'ask'
    " Sets v:fcs_choice = 'edit' or '', depending on user interaction.
    call s:FCSPromptPromptUser(l:echohl, l:msg, l:fpath)

    if v:fcs_choice == 'edit'
      let l:msg = 'Loaded changes'
      let l:flare = '💫'
    else
      let l:msg = 'Ignored changes'
      let l:flare = '👀'
    endif
  endif

  call s:FCSPromptEchomAfter(l:echohl, l:msg, l:fpath, l:flare)
endfunction

" ***

function! s:FCSPromptExpandFilePath() abort
  return substitute(expand('<afile>:p'), '^' .. expand('$HOME'), '~', '')
endfunction

" ***

" If file edited, reloads the buffer (sets v:fcs_choice = 'edit');
" or if file was deleted, keep the buffer (sets v:fcs_choice = '').
" - Note we don't set &modified if file was deleted, because it might
"   get recreated, and then a corresponding v:fcs_choice = 'edit'
"   will reload it automatically. And user won't see an empty buffer
"   while it was deleted, but will see the old file contents.
" There's also just 'reload' which doesn't do all the stuff,
" like reading a modeline. (Unsure: What about BufEnter, etc.?)

function! s:FCSPromptAutoChoose(fcs_choice) abort
  let v:fcs_choice = a:fcs_choice
endfunction

" -------------------------------------------------------------------

" Note that MacVim reverses the button order — So the first choice is
" printed second (on the right).
"
" - E.g., if {choices} is "&Load File\n&Ignore", then the buttons
"   are shown like: [Ignore] [Load File]
"
" - ALERT: Author finds the dialog behavior a little... wonky.
"
"   - MacVim always returns 1 if you hit <Enter>. *Always*.
"
"   - MacVim returns the index for the highlighted button
"     if you hit <Space>.
"
"     - The default highlighted button is the second button,
"       [Ignore] — so if you hit <Space> immediately, you
"       select [Ignore].
"
"     - Or you can hit <Tab> to select [Load File], and then
"       <Space> (or <Enter>) to select it.
"
"       - If you hit <Tab> again, [Ignore] is highlighted,
"         and <Space> will select it (but not <Enter>,
"         which is *always* tied to the [Load File] action).
"
"   - Author finds this a little wonky because of hwo the
"     dialog looks initially — You'll see that the first choice
"     ([Load File], which is the button on the right) has a
"     blue background, but the other button ([Ignore]) has a
"     blue border around it.
"
"     - So it looks like both buttons are active!
"
"     - Also, <Tab> moves the highlight. Which makes sense.
"
"     - It wasn't until I realized that
"         Blue Background = <Enter>
"       And
"         Blue Border = <Space>
"       that I got it. (Is this normal macOS design? Maybe
"       I just don't know macOS design patterns very well.)

" - See comments up top re: How normal MacVim dialog looks
"     (see also doc/MacVim-FCS-prompt--builtin.png).
" - On Linux, the normal file-changed prompt looks like:
"     "Warning: File \"" .. l:afile .. "\" has changed since editing started\n"
"     \ .. "See \":help W11\" for more info."

function! s:FCSPromptPromptUser(echohl, msg, fpath)
  call s:FCSPromptEchoEphemeral(a:echohl, a:msg)

  let l:dialog_msg = a:msg .. "\n\n" .. a:fpath .. s:dialog_loadf_hint

  " Dialog type options:
  " - With MATE dialog icons noted:
  "   - Error (-), Question (?), Info (i), Warning /\, or Generic (i).
  " - With MacVim dialog icons noted:
  "   - Error /\, Question (V), Info (V), Warning (V), or Generic (V).
  "   - Where /\ is ⚠️  with a Vim logo overlayed, and (V) is just the
  "     Vim icon. I.e., all MacVim dialog types except 'Error' use the
  "     same Vim icon for the dialog.
  " - Though in MacVim at least Error and Warning look the same.
  let l:diaglog_type = (a:echohl == 'ErrorMsg') && 'Error' || 'Warning'

  if has('macunix')
    " In MacVim, Ignore button is first (on the left), then Load File.
    let l:choices = "&Load File\n&Ignore"
  else
    let l:choices = "&Ignore\n&Load File"
  endif

  let l:user_response = confirm(
    \ l:dialog_msg,
    \ l:choices,
    \ s:button_index_load,
    \ l:diaglog_type
    \ )

  if l:user_response == s:button_index_load
    let v:fcs_choice = 'edit'
  else
    let v:fcs_choice = ''
  endif
endfunction

" ***

function! s:PrepareDialog()
  if !has('gui_running')
    " Don't add anything. E.g., user will see this in their message window:
    "   File changed!
    "
    "   ~/path/to/file
    "
    "   [L]oad File, (I)gnore:
    let s:dialog_loadf_hint = "\n"
    " Ignored
    let s:button_index_load =  1
  elseif has('macunix')
    " DUNNO: I only use MacVim, so not sure if the dialog is different on
    " other flavors of Vim on Mac.
    " - Because we might want to adjust this accordingly, e.g.,
    "     if has('gui_macvim') | ... | elseif has('osxdarwin') | ...
    " let s:dialog_loadf_hint = "\n\nEnter to Load File\nTab/Space follows highlight"
    let s:dialog_loadf_hint = "\n\n<Enter> to Load File\n<Tab>/<Space> follows highlight"
    " As noted above, MacVim doesn't honor the index value.
    " - <Enter> will always send 1.
    " - <Space> will send index of button with highlight.
    "   - Defaults 2nd button, can be moved with <Tab>.
    let s:button_index_load =  1
  else
    " Interestingly, just a few extra character will make dialog 50% wider:
    "   let s:dialog_loadf_hint = "\n\nPress <Enter> or <Space> to Load File"
    " Compared to this:
    "   let s:dialog_loadf_hint = "\n\nPress Enter or Space to reload"
    let s:dialog_loadf_hint = "\n\nPress Enter or Space to Load File"
    " In Linux Mint MATE, <Space> and <Enter> each return s:button_index_load.
    " - And <Tab> doesn't work, but <Alt-I> [Ignore] and <Alt-L> [Load File]
    "   work.
    let s:button_index_load =  2
  endif
endfunction

" -------------------------------------------------------------------

" Show an ephemeral message while the dialog is showing. (Not that
" the user is likely to notice, at least on MacVim the window dims
" somewhat).
"
" But don't show this message if there's no GUI.
" 
" - If there's no GUI, if we echo now, when prompt runs it adds
"   to message queue, so user would see *both* messages.
"
" - E.g., user might see this:
"
"     File changed! — foo
"     File changed!
"
"     ~/path/to/file
"
"     [L]oad File, (I)gnore:

function! s:FCSPromptEchoEphemeral(echohl, msg)
  if !has('gui_running')

    return
  endif

  let l:fname = expand('<afile>:t')

  echohl a:echohl
  echo a:msg .. ' — ' .. l:fname
  echohl None
endfunction

" ***

" If we echo now, the message precedes a Vim message that comes after, e.g.,
"
"   Timestamp changed — ~/path/to/some/README.rst
"   "README.rst" 492L, 32191B
"
" But if we set a 0-timeout timer, we'll print after the Vim message. (We win!)
"
" REFER: See also FileChangedShellPost. Using a timer precludes us from adding
" another autocmd, and also caching the message (e.g., s:pending_msgs = [...]).

function! s:FCSPromptEchomAfter(echohl, msg, fpath, flare)
  let l:full_msg = a:msg .. ' ' .. a:flare .. ' ' .. a:fpath

  call timer_start(0, { -> execute(
    \ 'echohl ' .. a:echohl ..
    \ " | echom '" .. l:full_msg .. "'" ..
    \ ' | echohl None',
    \ '')})
endfunction

" -------------------------------------------------------------------

function! s:CreateAutocmd_FileChangedShell() abort
  augroup BetterFCSGroup
    " Remove! autocommand group.
    autocmd! BetterFCSGroup

    autocmd BetterFCSGroup FileChangedShell * call g:embrace#fcs_prompt#FCSPrompt()
  augroup END
endfunction

" -------------------------------------------------------------------

function! g:embrace#fcs_prompt#Run() abort
  call s:PrepareDialog()
  call s:CreateAutocmd_FileChangedShell()
endfunction

