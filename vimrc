runtime! debian.vim
syntax on
set autoindent
set cindent
set expandtab
set ts=4
set nu
set ru
"set cursorcolumn
autocmd BufNewFile *.py,*.sh, exec ":call SetTitle()"
let $author_name = "kellanfan"
func SetTitle()  
    if &filetype == 'python'  
        call setline(1, "\#coding=utf8")  
        call setline(2, "\"\"\"")  
        call setline(3, "\# Author: ".$author_name)  
        call setline(4, "\# Created Time : ".strftime("%c"))  
        call setline(5, "")  
        call setline(6, "\# File Name: ".expand("%"))  
        call setline(7, "\# Description:")  
        call setline(8, "")  
        call setline(9, "\"\"\"")  
        call setline(10,"")  
    endif  
    if &filetype == 'sh'  
        call setline(1, "\#!/bin/bash")  
        call setline(2, "\#######################################################################")  
        call setline(3, "\#Author: ".$author_name)  
        call setline(4, "\#Created Time : ".strftime("%c"))  
        call setline(5, "\#File Name: ".expand("%"))  
        call setline(6, "\#Description:")  
        call setline(7, "\#######################################################################")  
        call setline(8,"")  
    endif  
endfunc  
