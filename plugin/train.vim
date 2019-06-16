let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 TrainLateInfo call train#run()

let &cpo = s:save_cpo
unlet s:save_cpo
