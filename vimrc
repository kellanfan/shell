runtime! debian.vim
syntax on
set autoindent
set cindent
set shiftwidth=4
set expandtab
"注释编程绿色，显示清楚
highlight Comment ctermfg=green guifg=green 
set ts=4
set nu
set ru
"set cursorcolumn
autocmd BufNewFile *.py,*.sh, exec ":call SetTitle()"
let $author_name = "kellanfan"
func SetTitle()  
    if &filetype == 'python'  
        call setline(1, "\#/usr/bin/env python")  
        call setline(2, "\#coding=utf8")  
        call setline(3, "\"\"\"")  
        call setline(4, "\# Author: ".$author_name)  
        call setline(5, "\# Created Time : ".strftime("%c"))  
        call setline(6, "")  
        call setline(7, "\# File Name: ".expand("%"))  
        call setline(8, "\# Description:")  
        call setline(9, "")  
        call setline(10, "\"\"\"")  
        call setline(11,"")  
    endif  
    if &filetype == 'sh'  
        call setline(1, "\#!/usr/bin/env bash")  
        call setline(2, "\#######################################################################")  
        call setline(3, "\#Author: ".$author_name)  
        call setline(4, "\#Created Time : ".strftime("%c"))  
        call setline(5, "\#File Name: ".expand("%"))  
        call setline(6, "\#Description:")  
        call setline(7, "\#######################################################################")  
        call setline(8,"")  
    endif  
endfunc  
