" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_train#Bitwise#import() abort', printf("return map({'lshift32': '', 'sign_extension': '', '_vital_created': '', 'rshift': '', 'rshift32': '', 'lshift': '', 'compare': ''}, \"vital#_train#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
" bitwise operators
" moved from github.com/ynkdir/vim-funlib

let s:save_cpo = &cpo
set cpo&vim

let s:bits = has('num64') ? 64 : 32
let s:mask = s:bits - 1
let s:mask32 = 32 - 1

let s:pow2 = [1]
for s:i in range(s:mask)
  call add(s:pow2, s:pow2[-1] * 2)
endfor
unlet s:i

let s:min = s:pow2[-1]

" compare as unsigned int
function! s:compare(a, b) abort
  if (a:a >= 0 && a:b >= 0) || (a:a < 0 && a:b < 0)
    return a:a < a:b ? -1 : a:a > a:b ? 1 : 0
  else
    return a:a < 0 ? 1 : -1
  endif
endfunction

function! s:lshift(a, n) abort
  return  a:a * s:pow2[s:and(a:n, s:mask)]
endfunction

function! s:rshift(a, n) abort
  let n = s:and(a:n, s:mask)
  return n == 0 ? a:a :
  \  a:a < 0 ? (a:a - s:min) / s:pow2[n] + s:pow2[-2] / s:pow2[n - 1]
  \          : a:a / s:pow2[n]
endfunction

if has('num64')
  " NOTE:
  " An int literal larger than or equal to 0x8000000000000000 will be rounded
  " to 0x7FFFFFFFFFFFFFFF after Vim 8.0.0219, so create it without literal
  let s:xFFFFFFFF00000000 = has('patch-8.0.0219')
        \ ? 0xFFFFFFFF * s:pow2[and(32, s:mask)]
        \ : 0xFFFFFFFF00000000
  function! s:sign_extension(n) abort
    if and(a:n, 0x80000000)
      return or(a:n, s:xFFFFFFFF00000000)
    else
      return and(a:n, 0xFFFFFFFF)
    endif
  endfunction
  function! s:lshift32(a, n) abort
    return and(s:lshift(a:a, and(a:n, s:mask32)), 0xFFFFFFFF)
  endfunction
  function! s:rshift32(a, n) abort
    return s:rshift(and(a:a, 0xFFFFFFFF), and(a:n, s:mask32))
  endfunction
else
  function! s:sign_extension(n) abort
    return a:n
  endfunction
endif


let s:builtin_functions_exist = exists('*and')
function! s:_vital_created(module) abort
  if s:builtin_functions_exist
    for op in ['and', 'or', 'xor', 'invert']
      let a:module[op] = function(op)
      let s:[op] = a:module[op]
    endfor
  endif
  if !has('num64')
    let a:module.lshift32 = a:module.lshift
    let a:module.rshift32 = a:module.rshift
  endif
endfunction

if s:builtin_functions_exist
  finish
endif


function! s:invert(a) abort
  return -a:a - 1
endfunction

function! s:and(a, b) abort
  let a = a:a < 0 ? a:a - s:min : a:a
  let b = a:b < 0 ? a:b - s:min : a:b
  let r = 0
  let n = 1
  while a && b
    let r += s:and[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) && (a:b < 0)
    let r += s:min
  endif
  return r
endfunction

function! s:or(a, b) abort
  let a = a:a < 0 ? a:a - s:min : a:a
  let b = a:b < 0 ? a:b - s:min : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:or[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) || (a:b < 0)
    let r += s:min
  endif
  return r
endfunction

function! s:xor(a, b) abort
  let a = a:a < 0 ? a:a - s:min : a:a
  let b = a:b < 0 ? a:b - s:min : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:xor[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) != (a:b < 0)
    let r += s:min
  endif
  return r
endfunction

let s:and = [
      \ [0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0],
      \ [0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1],
      \ [0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2],
      \ [0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3],
      \ [0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4, 0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4],
      \ [0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5, 0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5],
      \ [0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6, 0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6],
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8],
      \ [0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x8, 0x9, 0x8, 0x9, 0x8, 0x9, 0x8, 0x9],
      \ [0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x8, 0x8, 0xA, 0xA, 0x8, 0x8, 0xA, 0xA],
      \ [0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x8, 0x9, 0xA, 0xB, 0x8, 0x9, 0xA, 0xB],
      \ [0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4, 0x8, 0x8, 0x8, 0x8, 0xC, 0xC, 0xC, 0xC],
      \ [0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5, 0x8, 0x9, 0x8, 0x9, 0xC, 0xD, 0xC, 0xD],
      \ [0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6, 0x8, 0x8, 0xA, 0xA, 0xC, 0xC, 0xE, 0xE],
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF]
      \ ]

let s:or = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x1, 0x3, 0x3, 0x5, 0x5, 0x7, 0x7, 0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF],
      \ [0x2, 0x3, 0x2, 0x3, 0x6, 0x7, 0x6, 0x7, 0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF],
      \ [0x3, 0x3, 0x3, 0x3, 0x7, 0x7, 0x7, 0x7, 0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF],
      \ [0x4, 0x5, 0x6, 0x7, 0x4, 0x5, 0x6, 0x7, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF],
      \ [0x5, 0x5, 0x7, 0x7, 0x5, 0x5, 0x7, 0x7, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF],
      \ [0x6, 0x7, 0x6, 0x7, 0x6, 0x7, 0x6, 0x7, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF],
      \ [0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF, 0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF],
      \ [0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF, 0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF],
      \ [0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF, 0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF],
      \ [0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF],
      \ [0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF],
      \ [0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF],
      \ [0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF]
      \ ]

let s:xor = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6, 0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE],
      \ [0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5, 0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD],
      \ [0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4, 0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC],
      \ [0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB],
      \ [0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2, 0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA],
      \ [0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1, 0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9],
      \ [0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0, 0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE, 0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6],
      \ [0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD, 0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5],
      \ [0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC, 0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4],
      \ [0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3],
      \ [0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA, 0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2],
      \ [0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9, 0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1],
      \ [0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0]
      \ ]

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
