{ pkgs, lib, ... }:

with builtins;
let
  ifBlock = cond: block:
    let blockstr = if isList block then lib.strings.concatStringsSep "\n  " block else "  " + block;
    in ''
      if ${cond}
      ${blockstr}
      endif
    '';
  has = cond: "has('${cond}')";
  set = val:
    if isString val then "set ${val}"
    else if isList val then "set ${lib.strings.concatStringsSep " " val}"
    else if isAttrs val then assert length (values val) == 1; "set ${head (attrNames val)}=${toString (head (lib.attrsets.attrValues val))}" # only work with one assignment for now
    else assert false; "";
  letifexists = key: val: (ifBlock "! exists(\"${key}\")" "let ${key} = ${val}");
in
{
  extraConfig = lib.strings.concatStringsSep "\n" [
    # DEFAULTS
    (ifBlock (has "folding") [
      (ifBlock (has "windows")
        "let &fillchars='vert: '"  # less cluttered vertical window separators
      )
      (set "foldenable")         # allow folds
      (set "foldmethod=indent")  # Use indentation for folds (not as slick as `syntax`, but faster.
      (set "foldnestmax=5")
      (let
        startunfolded = true;
      in set (if startunfolded then "foldlevelstart=99" else "foldlevelstart=1"))
      (set "foldcolumn=0")
      (set "foldopen-=block")    # when a fold is made, allow moving with "}" past the fold, without opening/deleting that fold
      "nnoremap <s-tab> za"      # toggle fold at current posision with s-tab (to avoid collision between <tab> and <c-i>
    ])

    # technically we don't need this anymore since we are configuring in nix!
    ''
    augroup vimrcFold
      " fold rc itself by categories
      autocmd!
      autocmd FileType vim set foldmethod=marker
      autocmd FileType vim set foldlevel=0
    augroup END
    ''
    # With a map leader it's possible to do extra key combinations
    # like <leader>w saves the current file
    (let leader = ''"\<space>"'';
      in lib.strings.concatStringsSep "\n" ([
        (letifexists "mapleader"   leader)
        (letifexists "g:mapleader" leader)
      # Allow the normal use of "," by pressing it twice
      ] ++ lib.optional (leader == ",") ["noremap ,, ,"])
    )

    # Leader key timeout
    (set "tm=2000")
    # Use par for prettier line formatting
    ''
    set formatprg=par
    let $PARINIT = 'rTbgqR B=.,?_A_a Q=_s>|'
    ''

    # Kill the damned Ex mode.
    #nnoremap Q <nop>"

    # Make <c-h> work like <c-h> again (this is a problem with libterm)
    (ifBlock (has "nvim") "nnoremap <BS> <C-w>h")

    # color anything greater than 80 characters as an error
    ''
    highlight OverLength ctermbg=Black guibg=Black
    " match OverLength '\%>81v.\+'
    match OverLength '\%>86v.\+'
    " match ErrorMsg '\%>101v.\+'
    ''
    # When hitting , insert combination of t and spaces for this width.
    # This combination is deleted as if it were 1 t when using backspace.
    "set softtabstop=2"
    # Set code-shifting width. Since smarttab is enabled, this is also the tab
    # insert size for the beginning of a line.
    "set shiftwidth=2"

    # ensure that markdown files have a textwidth of 120
    "au BufRead,BufNewFile *.md setlocal textwidth=120"

    # # adjust python files to uniform formatting
    # ''
    # " au BufNewFile,BufRead *.py
    # "     \ set tabstop=4
    # "     \ set softtabstop=4
    # "     \ set shiftwidth=4
    # "     \ set textwidth=120
    # "     \ set expandtab
    # "     \ set autoindent
    # "     \ set fileformat=unix
    # ''

    # Python ignores
    ''
    set wildignore+=__pycache__/*,*.py[cod],*$py.class,*.ipynb,.Python,env/*,build/*
    set wildignore+=develop-eggs/*,dist/*,downloads/*,eggs/*,.eggs/*,lib/*,lib64/*
    set wildignore+=parts/*,sdist/*,var/*,*.egg-info/*,.installed.cfg,*.egg,*.manifest
    set wildignore+=*.spec,pip-log.txt,pip-delete-this-directory.txt,htmlcov/*
    set wildignore+=__pycache__/*,.tox/*,.coverage,.coverage.*,.cache,nosetests.xml
    set wildignore+=coverage.xml,cover,.hypothesis/*,*.mo,*.pot,*.log,local_settings.py
    set wildignore+=instance/*,.webassets-cache,.scrapy,docs/_build/*,target/*
    set wildignore+=.ipynb_checkpoints,.python-version,celerybeat-schedule,.env,venv/*
    set wildignore+=ENV/*,.spyderproject,.ropeproject,.DS_Store,*.sublime-workspace
    ''

    # Read coco format as python (coco is "functional python")
    "au! BufNewFile,BufRead *.coco set filetype=python"

    # VIM user interface {{{
    # This is the default in neovim (and might cause problems when set)
    # "set encoding=utf-8"                     # use sane encodings
    "set nocompatible"                         # don't care about vi
    "filetype plugin indent on"                # enable file type detection
    ################################################################################################
    # How do these interact???
    "set smartcase"                            # When searching try to be smart about cases
    "set ignorecase"                           # ignore case on commands and searching
    "set wildignorecase"                       # case-insensitive search
    ################################################################################################
    "set incsearch"                            # Makes search act like search in modern browsers
    "set number relativenumber"                # set hybrid-number-d gutters
    "set autoread"                             # auto-reload files when they are changed (like via git)
    "set history=700"                          # Set lines of history
    "set shell=bash"                           # ensure that we always use bash
    "set tw=120"                               # set textwidth to be 120 globally
    "set hlsearch"                             # Enable search highlighting
    "set mouse=a"                              # Enable mouse in all modes
    "set so=7"                                 # Set 7 lines to the cursor - when moving vertically using j/k
    "set hidden"                               # don't close buffers when you aren't displaying them
    "set wildmenu"                             # Turn on the WiLd menu
    "set wildmode=list:longest,full"           # Tab-complete files up to longest unambiguous prefix
    "set cmdheight=1"                          # Height of the command bar
    "set lazyredraw"                           # Don't redraw while executing macros (good performance config)
    "set magic"                                # For regular expressions turn magic on
    "set showmatch"                            # Show matching brackets when text indicator is over them
    "set mat=2"                                # How many tenths of a second to blink when matching brackets
    "set noerrorbells" "set vb t_vb="          # No annoying sound on errors
    "set termguicolors"                        # use "true color" in the terminal
    "set nobackup" "set nowb" "set noswapfile" # Turn backup off, since most stuff is in Git anyway...
    "set expandtab"                            # Use spaces instead of tabs
    "set smarttab"                             # Be smart when using tabs ;)
    "set shiftwidth=2" "set tabstop=2"         # 1 tab == 2 spaces
    "set lbr" "set tw=500"                     # Linebreak on 500 characters
    "set ai"                                   # Auto indent
    "set si"                                   # Smart indent
    "set wrap"                                 # Wrap lines
    "set ffs=unix,dos,mac"                     # Use Unix as the standard file type
    "set laststatus=2"                         # Always show the status line
    "set list"                                 # Show trailing whitespace
    "set listchars=tab:▸▸,trail:·"             # Show `▸▸` for tabs: 	, `·` for tailing whitespace
    "set clipboard=unnamed"                    # Use the system clipboard
    # TEST THESE
    "set cursorline"                           # show an underline for the current cursor position
    "set ruler"         # DO I WANT THIS WITH STATUSLINE?    # show file and line position info on bottom right
    "set autoindent"
    "set smartindent"
    "set laststatus=2"
    "set ignorecase"
    "set smartcase"
    "set undofile"
    "set undodir=${builtins.getEnv "HOME"}/.config/nvim/undodir" # note you must `mkdir -p ~/.config/nvim/undodir`
    "set undolevels=1000"
    "set undoreload=10000"

    # change the speed of upward and downward scrolling
    "nnoremap <C-e> 3<C-e>"
    "nnoremap <C-y> 3<C-y>"

    # set behaviors to be invoked using :make
    "autocmd Filetype python setlocal makeprg=python3\\ %"
    "autocmd Filetype c setlocal makeprg=make\\ clean\\ test"
    "autocmd Filetype text,markdown setlocal nocindent"

    # "set nohlsearch"                           # <<<<< actually don't highlight ??????
    # And never type :nohlsearch again!!!
    "nnoremap <esc><esc> :noh<return><esc>"
    # "nnoremap <silent> <esc> <esc>:silent :nohlsearch<cr>"

    # ..but only interesting whitespace
    ''
    if &listchars ==# 'eol:$'
      set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
    endif
    ''

    # Configure backspace so it acts as it should act
    "set backspace=eol,start,indent"
    "set whichwrap+=<,>,h,l"

    # disable Background Color Erase (BCE) so that color schemes
    # render properly when inside 256-color tmux and GNU screen.
    # see also http://snk.tuxfamily.org/log/vim-256color-bce.html
    (ifBlock "&term =~ '256color'" "set t_ut=")

    # http://vimdoc.sourceforge.net/htmldoc/options.html#'autowrite'
    # https://web.archive.org/web/20191003035623/http://vimdoc.sourceforge.net/htmldoc/options.html
    # Write the contents of the file, if it has been modified, on each :next,
    # :rewind, :last, :first, :previous, :stop, :suspend, :tag, :!, :make, CTRL-]
    # and CTRL-^ command;
    # "set autowrite"
    # If you want to save on _every_ action: autowriteall (includes :edit, :quit, :qall, etc)
    "set autowriteall"

    # ex mode is basically useless, and we often get there accidentally, so disable it
    "map q: <Nop>"
    "nnoremap Q <nop>"

    # Force redraw
    "map <silent> <leader>r :redraw!<CR>"

    # Turn mouse mode on
    "nnoremap <leader>ma :set mouse=a<cr>"

    # Turn mouse mode off
    "nnoremap <leader>mo :set mouse=<cr>"

    "tnoremap <Esc> <C-\\><C-n>"
    "set encoding=utf-8"

    # Allow saving of files as sudo when I forgot to start vim using sudo.
    "cmap w!! w !sudo tee > /dev/null %"

    # Text, tab and indent related {{{

    # Copy and paste to os clipboard
    ''
    nmap <leader>y "+y
    vmap <leader>y "+y
    nmap <leader>d "+d
    vmap <leader>d "+d
    nmap <leader>p "+p
    vmap <leader>p "+p
    ''

    # Don't blink normal mode cursor
    "set guicursor=n-v-c:block-Cursor"
    "set guicursor+=n-v-c:blinkon0"

    # only work in 256 colors
    "set t_Co=256"

    # strip trailing whitespace everywhere and save the cursor position
    # https://stackoverflow.com/a/1618401
    (let
      allfiles = false;
      files = if allfiles then "*" else "haskell,c,cpp,java,php,ruby,python,markdown";
    in ''
    fun! <SID>StripTrailingWhitespaces()
        let l = line(".")
        let c = col(".")
        %s/\s\+$//e
        call cursor(l, c)
    endfun
    autocmd FileType ${files} autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()
    '')

    # Visual mode related {{{

    # Visual mode pressing * or # searches for the current selection
    # Super useful! From an idea by Michael Naumann

    ''
    function! VisualSelection(direction, extra_filter) range
      let l:saved_reg = @"
      execute "normal! vgvy"

      let l:pattern = escape(@", '\\/.*$^~[]')
      let l:pattern = substitute(l:pattern, "\n$", "", "")

      if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
      elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.' . a:extra_filter)
      elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
      elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
      endif

      let @/ = l:pattern
      let @" = l:saved_reg
    endfunction

    vnoremap <silent> * :call VisualSelection('f', '''''')<CR>
    vnoremap <silent> # :call VisualSelection('b', '''''')<CR>
    ''
    # }}}

    # Spell checking {{{
    "map <leader>ss :setlocal spell!<cr>"               # Pressing ,ss will toggle and untoggle spell checking
    "au BufRead,BufNewFile *.md,*.tex setlocal spell!"  # turn on spell-checking by default for markdown and latex
    # }}}

    # Neovim terminal configurations
    (ifBlock (has "nvim") [
      # Use <Esc> to escape terminal insert mode
      "tnoremap <Esc> <C-\\><C-n>"
      # Make terminal split moving behave like normal neovim
      "tnoremap <c-h> <C-\\><C-n><C-w>h"
      "tnoremap <c-j> <C-\\><C-n><C-w>j"
      "tnoremap <c-k> <C-\\><C-n><C-w>k"
      "tnoremap <c-l> <C-\\><C-n><C-w>l"
    ])

    # Remember info about open buffers on close
    "set viminfo^=%"

    # Treat long lines as break lines (useful when moving around in them)
    "nnoremap j gj"
    "nnoremap k gk"

    "noremap <c-h> <c-w>h"
    "noremap <c-k> <c-w>k"
    "noremap <c-j> <c-w>j"
    "noremap <c-l> <c-w>l"

    # Open file prompt with current path
    ''nmap <leader>e :e <C-R>=expand("%:p:h") . '/'<CR>''

    # Tags {{{

    "set tags+=./tags;$HOME,./codex.tags;$HOME"
    "set cst"
    "set csverb"

    # IGNORES ARE HERE BECAUSE THEY INTERFERE WITH CTAG LOOKUP
    "set wildignore+=*.min.*"       # Web ignores
    "set wildignore+=*.stack-work*" # Haskell ignores
    "set wildignore+=*.so"          # C ignores

    # }}}

    # Spelling
    ''
    abbr Lunix Linux
    abbr accross across
    abbr hte the
    abbr Probablistic Probabilistic
    abbr cplus oplus
    ''
  ];
}
