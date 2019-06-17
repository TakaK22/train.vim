let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_train')
    finish
endif

let g:loaded_train = 1

command! -nargs=0 TrainLateInfo call train#late_info()
command! -nargs=+ TrainSearchRoute call train#route_search(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
