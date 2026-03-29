let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1  " 启用标签栏
let g:airline_theme = 'dark'                  " 设置主题（默认随配色方案自动切换）
let g:airline_left_sep = ''                  " 左侧分隔符（Powerline符号）
let g:airline_right_sep = ''                 " 右侧分隔符
let g:airline_section_c = '%t'                " 文件名显示格式
let g:airline_inactive_collapse = 1           " 折叠非活动窗口状态栏

let g:airline_section_a = '%{mode(1)}'        " 模式显示（INSERT/NORMAL等）
let g:airline_section_b = '%{airline#extensions#branch#get_head()}'  " Git分支
let g:airline_section_c = '%f %m'             " 文件名+修改状态
let g:airline_section_x = '%{&fileencoding?&fileencoding:&encoding}'  " 编码格式
let g:airline_section_y = '%{&filetype}'      " 文件类型
let g:airline_section_z = '%l/%L:%c'          " 行号/总行数:列号

let g:airline_theme = 'tomorrow'   " 匹配Tomorrow配色方案

:set number
:set tabstop=4
:set hlsearch

set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
 
" 插件列表（格式：Plugin '用户名/仓库名'）
Plugin 'VundleVim/Vundle.vim'       " Vundle 自身
Plugin 'preservim/nerdtree'         " 文件浏览器
Plugin 'tpope/vim-sensible'         " 基础配置增强
Plugin 'neoclide/coc.nvim', {'branch': 'release'}  " 代码补全
 
call vundle#end()
filetype plugin indent on  " 启用文件类型检测
