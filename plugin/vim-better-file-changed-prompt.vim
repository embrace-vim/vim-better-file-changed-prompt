" vim:tw=0:ts=2:sw=2:et:norl
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-better-file-changed-prompt#🗯
" License: License: CC0 1.0 <https://creativecommons.org/publicdomain/zero/1.0/>
"   Copyright © 2020, 2024 Landon Bouma.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_better_file_changed_prompt
endif

if exists('g:loaded_better_file_changed_prompt') || &cp

  finish
endif

let g:loaded_better_file_changed_prompt = 1

" -------------------------------------------------------------------

if get(g:, 'better_file_changed_prompt_disable', 0)

  finish
endif

" -------------------------------------------------------------------

" CXREF:
" ~/.kit/nvim/embrace-vim/start/vim-better-file-changed-prompt/autoload/embrace/fcs_prompt.vim
call g:embrace#fcs_prompt#Run()

