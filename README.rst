##############################################
Vim Plugin |em_dash| Nicer File Changed Prompt
##############################################

.. |em_dash| unicode:: 0x2014 .. em dash

About This Plugin
=================

This plugin makes two changes to the ``FileChangedShell`` prompt behavior:

1. The default selected button is 'Load File', so you can just press
   Return (or Space) to reload the file, which is usually the action
   you want. (And it's easy to undo — Press `Ctrl-z` and the changes
   are undone).

2. The prompt is not shown for certain types of changes that you
   shouldn't care about, like permissions changes.

USE CASE: If you rebase source code often, you'll find yourself needing
to fix conflicts, but when a file is changed outside of Vim, Vim prompts
you, asking if you want to reload it, but defaulting the selected dialog
button to not reloading the file. If you're tired of seeing this dialog,
and then pressing Tab or using the mouse to select 'Load File' instead of
'OK', then this plugin is for you!

NOTE: On Linux, pressing Space or Enter will accept the default dialog
choice ("Load File"), but on macOS (MacVim), you'll want to press Return
(as pressing Space will "OK" the dialog, which does not reload the file).

Installation
============

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/start
    cd ~/.vim/pack/landonb/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/opt
    cd ~/.vim/pack/landonb/opt

Clone the project to the desired path:

.. code-block:: bash

    git clone https://github.com/landonb/vim-nicer-file-changed-prompt.git

If you installed to the optional path (``opt``), tell Vim to load the package:

.. code-block:: vim

   :packadd! vim-nicer-file-changed-prompt

otherwise Vim will automatically load the plugin when installed to ``start``.

Just once, tell Vim to build the online help:

.. code-block:: vim

   :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

   :help vim-nicer-file-changed-prompt

