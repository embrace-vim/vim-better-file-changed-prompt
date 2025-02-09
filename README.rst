##################################################
File-Changed Prompt with "Load File" as Default 🗯
##################################################

This plugin adjusts the default file-changed prompt.

- You probably don't need this plugin it you're happy with |autoread|_.

  - If you're running Vim, ``autoread`` is not enabled by default.

    - Run ``set autoread`` and be happy.

  - If you're running Neovim, you're all set.

But if you want a few quality of life improvements,
sure, maybe check out this plugin!

- For ``vim-gtk`` and MacVim, it makes the prompt a
  little less wordy.

  - For MacVim specifically, it hints at how to use
    the somewhat confusing UX (*there are two buttons
    highlighted in blue — so what does pressing <Enter>
    do??*)

- It adds additional alerts where (Neo)Vim is otherwise
  silent.

  - For example, when |autoread|_ is enabled, if a buffer
    is unchanged but its external file changes, Vim loads
    the changes and prints a message.

    But in Neovim, nothing is printed.

    This plugin restores that message.

.. |autoread| replace:: ``autoread``
.. _autoread: https://vimhelp.org/options.txt.html#autoread

Prompt Differences
==================

By default, Vim prompts you if a buffer you're working on
was changed by an external program.

Here's a look at the default prompt on macOS in `MacVim <https://macvim.org/>`__:

.. image:: doc/MacVim-FCS-prompt--builtin.png
   :alt: Default MacVim file-changed prompt
   :align: center

If you're not familiar with macOS dialog wiring:

- The button with the *blue background* is picked
  when you press ``<Enter>``.

- The button with the *blue border* is picked when
  you press ``<Space>``.

- You can move the selected button with ``<Tab>``.

  - Regardless of the selected button, ``<Enter>`` will
    *always* pick the "OK" button.

- There are no accelerators defined (e.g., nothing like
  an ``<Alt-L>`` accelerator you might find on Linux).

This plugin changes the prompt thusly:

.. image:: doc/MacVim-FCS-prompt--better.png
   :alt: Improved MacVim file-changed prompt
   :align: center

You'll see that the prompt text is a little less wordy than the
default, and there's a helpful little hint added to remind you
how ``<Enter>`` and ``<Tab>``/``<Space>`` work on macOS.

- And if you've read |help-W11|_ once, you probably
  don't need to be reminded of it every time.

.. |help-W11| replace:: ``:help W11``
.. _help-W11: https://vimhelp.org/message.txt.html#W11

In the other Vims — Linux GVim, terminal ``vim``, and terminal
``nvim`` — you'll see similar changes to the prompt.

The different types of Vim file changes
=======================================

Vim identifies at least six different types of changes:

- The file on disk was deleted while a buffer is open.

- The file timestamp was changed.

- The file permissions were changed.

- The file contents were changed, but the buffer has
  not been modified (|help-modified|_).

- The file contents were changed and the buffer has
  local modifications.

- The file on disk was *created* after a buffer with
  that path was opened.

  - This is actually a different prompt altogether
    that is not scriptable (|help-W13|_).

How this plugin handles each of those file changes
--------------------------------------------------

If Vim notices that a file is deleted while a buffer is open,
it alerts, ``E211: File "{filepath}" no longer available``,
but it doesn't prompt.

- If the file is created again, Vim doesn't announce it,
  unless the local buffer has changes.

  - So this plugin emits a message when the deleted file
    has since been *undeleted*.

If Vim notices that only the timestamp has changed, it
won't alert you. It will ignore the event and move on.

- This plugin will instead print a short `message
  <https://vimhelp.org/message.txt.html#%3Amessages>`__
  to bleep you, |because-what-the-hay|_ (but it won't
  prompt you).

- For you |rebasers|_ out there, this event occurs
  frequently when you rebase history.

If Vim notices that the permissions have changed,
the Vim default is to always prompt you.

- This plugin will *not* prompt you when permissions
  change. [Although maybe it should, or at least if
  the file is no longer writable or readable by the
  user. But that's a rare use case we're not gonna
  worry about. But please open an `Issue
  <https://github.com/embrace-vim/vim-better-file-changed-prompt/issues>`__
  if this impacts you negatively.]

If Vim notices external changes and the local buffer
has not been modified, it'll print a message like you'd
normally see when you edit a file, e.g.,:

  ``"file" 3L, 9B``

- Interestingly, in Neovim, nothing is messaged. Neovim
  silently loads changes.

- This plugin prints an alert like Vim does, but telling you
  explicitly what happened (unlike, e.g., ``"file" 3L, 9B``),
  and colorfully, too (imagine the following with a yellow
  background, for example), e.g.,:

  ``File changed! 📠 /path/to/file``

Finally, when conflicts are detected, this plugin will prompt
you, just like Vim or Neovim does, regardless of ``autoread``,
albeit with the dialog changes described earlier.

.. |help-modified| replace:: ``:help modified``
.. _help-modified: https://vimhelp.org/options.txt.html#%27modified%27

.. |help-W13| replace:: ``:help W13``
.. _help-W13: https://vimhelp.org/message.txt.html#W13

.. |rebasers| replace:: *rebasers*
.. _rebasers: https://git-scm.com/docs/git-rebase

.. |because-what-the-hay| replace:: *because what the hay*
.. _because-what-the-hay: https://www.google.com/search?q=define+hay

Reference
=========

Relevant Vim documentation for the *endlessly curious*:

- |help-FileChangedShell|_

- |help-fcs_choice|_

- |help-fcs_reason|_

- |help-timestamp|_

- |help-autoread|_

- Vim Tip: *File no longer available - mark buffer modified*, by *Ewfalor*, 2008:

  `https://vim.fandom.com/wiki/File_no_longer_available_-_mark_buffer_modified
  <https://vim.fandom.com/wiki/File_no_longer_available_-_mark_buffer_modified>`__

  - This tip provides a simple ``FileChangedShell`` hander that was the basis
    for this project's `file-changed handler
    <https://github.com/embrace-vim/vim-better-file-changed-prompt/blob/release/autoload/embrace/fcs_handler.vim>`__.

.. |help-FileChangedShell| replace:: ``:h FileChangedShell``
.. _help-FileChangedShell: https://vimhelp.org/autocmd.txt.html#FileChangedShell

.. |help-fcs_choice| replace:: ``:h v:fcs_choice``
.. _help-fcs_choice: https://vimhelp.org/eval.txt.html#v%3Afcs_choice

.. |help-fcs_reason| replace:: ``:h v:fcs_reason``
.. _help-fcs_reason: https://vimhelp.org/eval.txt.html#v%3Afcs_reason

.. |help-timestamp| replace:: ``:h timestamp``
.. _help-timestamp: https://vimhelp.org/editing.txt.html#timestamp

.. |help-autoread| replace:: ``:h autoread``
.. _help-autoread: https://vimhelp.org/options.txt.html#%27autoread%27

So, like, *Why?*
================

I originally made this plugin because I wanted to be prompted
when external changes happened, even if there was no conflict,
so that I could choose what to do. But I wanted the default
choices to be opposite Vim's — e.g., if ``set noautoread`` and
Vim shows the conflict prompt, the default is to Keep Changes,
but I wanted the default to be Load File.

- So when no conflicts, I wanted to be able to hit <Enter> to
  load changes.

- But when there were conflicts, I wanted to be able to hit
  <Enter> to ignore changes.

Nowadays, I prefer ``autoload`` behavior — not to be prompted
when there are external changes but not conflicts, but to just
load changes — but I also like the additional messages provided
by this plugin.

Related Projects
================

- ``interuptless.vim`` — *Makes vim interrupt you less*

  https://github.com/vim-utils/vim-interruptless

- ``vim-autoread`` — Have Vim automatically reload a
  file that has changed externally

  https://github.com/djoshea/vim-autoread

Installation
============

.. |help-packages| replace:: ``:h packages``
.. _help-packages: https://vimhelp.org/repeat.txt.html#packages

.. |INSTALL.md| replace:: ``INSTALL.md``
.. _INSTALL.md: INSTALL.md

Take advantage of Vim's packages feature (|help-packages|_)
and install under ``~/.vim/pack``, e.g.,:

.. code-block::

  mkdir -p ~/.vim/pack/embrace-vim/start
  cd ~/.vim/pack/embrace-vim/start
  git clone https://github.com/embrace-vim/vim-better-file-changed-prompt.git

  " Build help tags
  vim -u NONE -c "helptags vim-better-file-changed-prompt/doc" -c q

- Alternatively, install under ``~/.vim/pack/emrace-vim/opt`` and call
  ``:packadd vim-better-file-changed-prompt`` to load the plugin on-demand.

For more installation tips — including how to easily keep the
plugin up-to-date — please see |INSTALL.md|_.

Attribution
===========

.. |embrace-vim| replace:: ``embrace-vim``
.. _embrace-vim: https://github.com/embrace-vim

.. |@landonb| replace:: ``@landonb``
.. _@landonb: https://github.com/landonb

The |embrace-vim|_ logo by |@landonb|_ contains
`coffee cup with straw by farra nugraha from Noun Project
<https://thenounproject.com/icon/coffee-cup-with-straw-6961731/>`__
(CC BY 3.0).

