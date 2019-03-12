""Type ':h setting' in vim for help on the following settings

"" Use Vim settings, rather than Vi settings.
"" This must come before any other settings since it has side effects on other options.
set nocompatible


"" Functions
"" =========
function! IsPlugin(plugin_name)
    return isdirectory( expand("$HOME/.vim/bundle/" . a:plugin_name ) )
endfunction


"" Plugins - Vundle
"" ================
"" Install vundle if necessary
if !IsPlugin('Vundle.vim')
    silent !mkdir -p ~/.vim/bundle
    silent !git clone https://github.com/VundleVim/Vundle.vim ~/.vim/bundle/Vundle.vim
    let install_plugins = 1
else
    let install_plugins = 0
endif

"" turn off filetype temporarily
filetype on
filetype off

"" Add vundle and any other packages not installed through vundle to our lookup path
set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()

"" The Vundle plugin. Requiered by Vundle
Plugin 'VundleVim/Vundle.vim'

"" Appearence
"" ----------
" "" Solarized colorscheme for vim
" Plugin 'altercation/vim-colors-solarized'
"" GruvBox theme
Plugin 'morhetz/gruvbox'
Plugin 'shinchu/lightline-gruvbox.vim'
" "" Vim Airline + Themes = status/tabline
" Plugin 'bling/vim-airline'
" Plugin 'vim-airline/vim-airline-themes'
"" lightline - A light and configurable statusline/tabline plugin for Vim
Plugin 'itchyny/lightline.vim'
"" Vim-Bufferline - Show buffers in the command bar
Plugin 'bling/vim-bufferline'
"" Rainbow parentheses - Set matching parentheses to have unique colors
Plugin 'kien/rainbow_parentheses.vim'
"" vim-minimap - A code minimap for Vim
Plugin 'severin-lemaignan/vim-minimap'
" "" indentLine - A vim plugin to display the indention levels with thin vertical lines
" Plugin 'Yggdroot/indentLine'

"" Editing
"" -------
"" YouCompleteMe - Code completion
if (v:version > 704) || (v:version == 704 && has('patch143'))
    Plugin 'valloric/youcompleteme'
endif
"" commentary.vim - commenting plug-in
Plugin 'tpope/vim-commentary'
"" repeat.vim - enables repeating supported plug-in maps with "."
Plugin 'tpope/vim-repeat'
" "" Syntastic - Syntax checking
" Plugin 'scrooloose/syntastic'
"" Asynchronous Lint Engine - a plugin for providing linting in NeoVim and Vim 8 while you edit your text files
Plugin 'w0rp/ale'
"" vim-dirdiff - a tool for comparing directories
Plugin 'will133/vim-dirdiff'
"" vim.csv
Plugin 'chrisbra/csv.vim'
"" vim-mundo -  Vim undo tree visualizer
Plugin 'simnalamburt/vim-mundo'

"" Navigating
"" ----------
"" ack.vim - A regular expression search build around ack and ag
Plugin 'mileszs/ack.vim'
"" Vim Tmux navigator - Seamless navigation between tmux panes and vim splits
Plugin 'christoomey/vim-tmux-navigator'
"" NERD Tree
Plugin 'scrooloose/nerdtree'
"" # CtrlP - Fuzzy file, buffer, mru, tag, etc finder
Plugin 'kien/ctrlp.vim'
"" vim-buffer: A plugin to list, select and switch between buffers
Plugin 'jeetsukumaran/vim-buffergator'

"" Third parties
"" -------------
"" Fugitive - Git wrapper
Plugin 'tpope/vim-fugitive'
"" Vim gitgutter - shows a git diff in the 'gutter' (sign column)
Plugin 'airblade/vim-gitgutter'

"End Vundle
call vundle#end()

if (install_plugins == 1)
    :PluginInstall
endif

"" Appearance
"" ==========
set t_Co=256

"" Add column line
if (exists('+colorcolumn'))
    set colorcolumn=120
    highlight ColorColumn ctermbg=9
endif

" "" # Set colorscheme
" if IsPlugin("vim-colors-solarized")
"     " let g:solarized_termcolors=16
"     let g:solarized_termtrans=1
"     " let g:solarized_visibility="low"
"     set background=dark
"     colorscheme solarized
" endif
if IsPlugin("gruvbox")
    colorscheme gruvbox
    set background=dark
    " let g:gruvbox_contrast_dark='medium'
endif

" if IsPlugin("vim-airline-themes")
"     " " Enable powerline fonts
"     let g:airline_powerline_fonts = 1

"     " Set airline theme
"     let g:airline_theme='solarized'
" endif

if IsPlugin("lightline.vim")
    " Set lightline theme
    let g:lightline = {
        \ 'colorscheme': 'gruvbox',
        \ }
        " \ 'colorscheme': 'solarized',
endif

"" Vim config
"" ==========
"" Switch syntax highlighting on
syntax enable

"" standard encoding
" set encoding=utf-8

"" Tabs
"" ----
"" Replace tab with spaces
set expandtab
"" Set tab size
set tabstop=4
set softtabstop=4
"" Set indentation size
set shiftwidth=4

"" Save undo history for each file
set undofile

" "" Set symbols
" set listchars=tab:▸\ ,extends:»,precedes:«,eol:¬

"" Add line numbers
set number

"" Disable line wrapping
set nowrap

" "" Allow backspace in insert mode
" set backspace=indent,eol,start

"" Turn on the WiLd menu
set wildmenu

"" Reload files changed outside vim
set autoread

"" Allow hidden buffers, don't limit to 1 file per window/split
set hidden

"" Set command history buffer lenght (default=8)
set history=1000

"" Enable file type detection and do language-dependent indenting.
filetype plugin indent on

"" Show incomplete cmds down the bottom
set showcmd

"" Disable cursor blink
set gcr=a:blinkon0

"" Always show status line
set laststatus=2

" ""  Highlight current line
" set cursorline

"" Opens vertical split right of current window
set splitright

"" Opens horizontal split below current window
set splitbelow

"" Search Settings
"" ---------------
"" Find the next match as we type the search
set incsearch
"" Highlight searches by default
set hlsearch
"" Make search case insensitive unless it contains upper case
set ignorecase
set smartcase

"" Enable spell checking
set spell


"" Directories
"" ===========
if !isdirectory( expand("~/.vim/backup/") )
    call mkdir(expand("~/.vim/backup/"), 'p')
endif
set backupdir=~/.vim/backup//

if !isdirectory( expand("~/.vim/swap/") )
    call mkdir(expand("~/.vim/swap/"), 'p')
endif
set directory=~/.vim/swap//

if !isdirectory( expand("~/.vim/undo/") )
    call mkdir(expand("~/.vim/undo/"), 'p')
endif
set undodir=~/.vim/undo//


"" Key bindings
"" ============
" "" Enable mouse
" set mouse=a

"" Set leader
let mapleader = "\<Space>" " default: \

"" Shortcut to the Esc key
imap jk <Esc>

"" Map ; to :
nnoremap ; :
vnoremap ; :

"" Shortcut to reload ~/.vimrc
nnoremap <leader>rr :source ~/.vimrc<CR>
vnoremap <leader>rr :source ~/.vimrc<CR>

"" Shortcut to save file
nnoremap <leader>w :w<CR>
vnoremap <leader>w :w<CR>

"" Shortcut to copy, cut and paste to z register
nnoremap <leader>d "zd
vnoremap <leader>d "zd
nnoremap <leader>dd "zdd
vnoremap <leader>dd "zdd
nnoremap <leader>D "zD
vnoremap <leader>D "zD
nnoremap <leader>y "zy
vnoremap <leader>y "zy
nnoremap <leader>yy "zyy
vnoremap <leader>yy "zyy
nnoremap <leader>Y "zy$
vnoremap <leader>Y "zy$
nnoremap <leader>p "zp
vnoremap <leader>p "zp
nnoremap <leader>P "zP
vnoremap <leader>P "zP

"" Shortcuts for copying systems clipboard ('+' and '*' registers) to z register
nnoremap <leader>+ :let @z = @+<CR>
vnoremap <leader>+ :let @z = @+<CR>
nnoremap <leader>* :let @z = @*<CR>
vnoremap <leader>* :let @z = @*<CR>

"" Shortcuts for copying z register to systems clipboard ('+' and '*' registers)
nnoremap <leader>- :let @+ = @z <bar>let @* = @z<CR>
vnoremap <leader>- :let @+ = @z <bar>let @* = @z<CR>

"" Shortcut to rapidly toggle `set list`
nnoremap <leader>l :set list!<CR>
vnoremap <leader>l :set list!<CR>

"" Set <leader><space> to un-highlight last search
nnoremap <leader><space> :noh<CR>
vnoremap <leader><space> :noh<CR>

"" Quick toggle between absolute, relative line numbering and no line numbering
function! NumberToggle()
  if(&number == 0)
    set number
    set norelativenumber
  elseif(&number == 1 && &relativenumber == 0)
    set number
    set relativenumber
  else
    set nonumber
    set norelativenumber
  endif
endfunc
nnoremap <leader>n :call NumberToggle()<cr>
vnoremap <leader>n :call NumberToggle()<cr>

:au FocusLost * :set norelativenumber
:au FocusGained * :set relativenumber

"" Capture shell commands into a new buffer using :R <shell_command>
:command! -nargs=* -complete=shellcmd R enew | setlocal buftype=nofile bufhidden=hide noswapfile | r !<args>

"" Add shortcut for adding break point in vim
autocmd filetype python nnoremap <silent> <leader>i Oimport ipdb; ipdb.set_trace(context=21)  # XXX BREAKPOINT<esc>

"" Shortcut to add underline comment
nnoremap <silent> <leader>u yyp_w<C-v>$r-
nnoremap <silent> <leader>U yyp_w<C-v>$r=

"" Shortcut to remove all trailing white spaces
nnoremap <leader>c :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar><cr>
vnoremap <leader>c :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar><cr>

"" Toggle set paste using F2
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

"" CScope
"" ======
"" The following configuration was copied from the cscope web site:

"" This tests to see if vim was configured with the '--enable-cscope' option
"" when it was compiled.  If it wasn't, time to recompile vim...
if has("cscope")

    """"""""""""" Standard cscope/vim boilerplate

    " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
    set cscopetag

    " check cscope for definition of a symbol before checking ctags: set to 1
    " if you want the reverse search order.
    set csto=1

    " add any cscope database in current directory
    if filereadable("cscope.out")
        cs add cscope.out
    " else add the database pointed to by environment variable
    elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
    endif

    " show msg when any other cscope db added
    set cscopeverbose


    """"""""""""" My cscope/vim key mappings
    "
    " The following maps all invoke one of the following cscope search types:
    "
    "   's'   symbol: find all references to the token under cursor
    "   'g'   global: find global definition(s) of the token under cursor
    "   'c'   calls:  find all calls to the function name under cursor
    "   't'   text:   find all instances of the text under cursor
    "   'e'   egrep:  egrep search for the word under cursor
    "   'f'   file:   open the filename under cursor
    "   'i'   includes: find files that include the filename under cursor
    "   'd'   called: find functions that function under cursor calls
    "
    " Below are three sets of the maps: one set that just jumps to your
    " search result, one that splits the existing vim window horizontally and
    " diplays your search result in the new window, and one that does the same
    " thing, but does a vertical split instead (vim 6 only).
    "
    " I've used CTRL-\ and CTRL-@ as the starting keys for these maps, as it's
    " unlikely that you need their default mappings (CTRL-\'s default use is
    " as part of CTRL-\ CTRL-N typemap, which basically just does the same
    " thing as hitting 'escape': CTRL-@ doesn't seem to have any default use).
    " If you don't like using 'CTRL-@' or CTRL-\, , you can change some or all
    " of these maps to use other keys.  One likely candidate is 'CTRL-_'
    " (which also maps to CTRL-/, which is easier to type).  By default it is
    " used to switch between Hebrew and English keyboard mode.
    "
    " All of the maps involving the <cfile> macro use '^<cfile>$': this is so
    " that searches over '#include <time.h>" return only references to
    " 'time.h', and not 'sys/time.h', etc. (by default cscope will return all
    " files that contain 'time.h' as part of their name).


    " To do the first type of search, hit 'CTRL-\', followed by one of the
    " cscope search types above (s,g,c,t,e,f,i,d).  The result of your cscope
    " search will be displayed in the current window.  You can use CTRL-T to
    " go back to where you were before the search.
    "

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>


    " Using 'CTRL-spacebar' (intepreted as CTRL-@ by vim) then a search type
    " makes the vim window split horizontally, with search result displayed in
    " the new window.
    "
    " (Note: earlier versions of vim may not have the :scs command, but it
    " can be simulated roughly via:
    "    nmap <C-@>s <C-W><C-S> :cs find s <C-R>=expand("<cword>")<CR><CR>

    nmap <C-@>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@>d :scs find d <C-R>=expand("<cword>")<CR><CR>


    " Hitting CTRL-space *twice* before the search type does a vertical
    " split instead of a horizontal one (vim 6 and up only)
    "
    " (Note: you may wish to put a 'set splitright' in your .vimrc
    " if you prefer the new window on the right instead of the left

    nmap <C-@><C-@>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@><C-@>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@><C-@>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>


    """"""""""""" key map timeouts
    "
    " By default Vim will only wait 1 second for each keystroke in a mapping.
    " You may find that too short with the above typemaps.  If so, you should
    " either turn off mapping timeouts via 'notimeout'.
    "
    "set notimeout
    "
    " Or, you can keep timeouts, by uncommenting the timeoutlen line below,
    " with your own personal favorite value (in milliseconds):
    "
    "set timeoutlen=4000
    "
    " Either way, since mapping timeout settings by default also set the
    " timeouts for multicharacter 'keys codes' (like <F1>), you should also
    " set ttimeout and ttimeoutlen: otherwise, you will experience strange
    " delays as vim waits for a keystroke after you hit ESC (it will be
    " waiting to see if the ESC is actually part of a key code like <F1>).
    "
    "set ttimeout
    "
    " personally, I find a tenth of a second to work well for key code
    " timeouts. If you experience problems and have a slow terminal or network
    " connection, set it higher.  If you don't set ttimeoutlen, the value for
    " timeoutlent (default: 1000 = 1 second, which is sluggish) is used.
    "
    "set ttimeoutlen=100

endif

"" Plug-ins settings
"" =================
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '~'


if IsPlugin("ack.vim")
  " Make ack.vim use ag instead of ack
  let g:ackprg = 'ag --column'
endif

if IsPlugin("ctrlp.vim")
  let g:ctrlp_cmd = 'CtrlPMixed'
  let g:ctrlp_show_hidden = 1
endif

if IsPlugin("youcompleteme")
    " shortcuts
    " nnoremap <leader>gl :YcmCompleter GoToDeclaration<CR>
    " nnoremap <leader>gf :YcmCompleter GoToDefinition<CR>
    nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
    " Disable automatically opening the preview window
    set completeopt-=preview
endif

if IsPlugin("vim-buffergator")
    " Open Buffergator in horizontal bottom mode
    let g:buffergator_viewport_split_policy="B"
endif

if IsPlugin("syntastic")
    " set statusline+=%#warningmsg#
    " set statusline+=%{SyntasticStatuslineFlag()}
    " set statusline+=%*

    " Automatically add error and warnings to vim's location-list
    let g:syntastic_always_populate_loc_list = 1
    " Automatically check file when it is being opened
    let g:syntastic_check_on_open = 1
    " Disable check if saved just before quitting
    let g:syntastic_check_on_wq = 0

    " let g:syntastic_auto_loc_list = 1

    " Python settings
    " let g:syntastic_python_checkers = ['pylint']
    " let g:syntastic_python_pylint_post_args="--max-line-length=120 -d missing-docstring -d superfluous-parens -d redefined-outer-name -d old-style-class -d too-few-public-methods -d too-many-arguments -d line-too-long -d too-many-locals"
    let g:syntastic_python_checkers=['flake8']
    let g:syntastic_python_flake8_args='--ignore=E501,E123,E124,E266'
endif

if IsPlugin("ale")
    let g:ale_linters={'python': ['flake8', 'pylint']}
    let g:ale_python_flake8_options="--ignore=E501,E123,E124,E266"
endif

if IsPlugin("rainbow_parentheses.vim")
     let g:rbpt_colorpairs = [
        \ ['brown',       'RoyalBlue3'],
        \ ['darkgreen',   'firebrick3'],
        \ ['Darkblue',    'SeaGreen3'],
        \ ['darkcyan',    'RoyalBlue3'],
        \ ['darkred',     'SeaGreen3'],
        \ ['darkmagenta', 'DarkOrchid3'],
        \ ['brown',       'firebrick3'],
        \ ['darkmagenta', 'DarkOrchid3'],
        \ ['Darkblue',    'firebrick3'],
        \ ['darkgreen',   'RoyalBlue3'],
        \ ['darkcyan',    'SeaGreen3'],
        \ ['darkred',     'DarkOrchid3'],
        \ ['red',         'firebrick3'],
        \ ]
    au FileType * RainbowParenthesesLoadRound
    au FileType * RainbowParenthesesLoadBraces
    au FileType * RainbowParenthesesLoadSquare
    au FileType * RainbowParenthesesActivate
endif

"" File specific
"" =============
"" Only do this part when compiled with support for autocommands
if has("autocmd")
  "" Enable file type detection
  filetype on

  autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
endif

