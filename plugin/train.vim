let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_train_late_info')
    finish
endif

let g:loaded_train_late_info = 1

command! -nargs=0 TrainLateInfo call train#run()

let &cpo = s:save_cpo
unlet s:save_cpo
