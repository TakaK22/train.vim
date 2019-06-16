scriptencoding utf-8

" import vital modules
let s:V = vital#train#new()
let s:HTTP = s:V.import('Web.HTTP')
let s:TABLE = s:V.import('Text.Table')
let s:DATE = s:V.import('DateTime')

let s:last_popup = 0

function! train#run() abort
    let l:response = s:HTTP.get("https://rti-giken.jp/fhc/api/train_tetsudo/delay.json")

    if l:response.status != 200
        echohl ErrorMsg
        echo 'status:' .. l:response.status 'response:' .. l:response.content
        echohl None
        return
    endif

    let l:table = s:TABLE.new({
                \ 'columns': [{}, {}, {}],
                \ 'header': ['路線名', '鉄道', '更新時間']
                \ })

    let l:content = json_decode(l:response.content)

    for c in l:content
        call l:table.add_row([
                    \ c.name, 
                    \ c.company, 
                    \ s:DATE.from_unix_time(c.lastupdate_gmt).format('%F %T')
                    \ ])
    endfor

    call popup_close(s:last_popup)
    let s:last_popup = popup_create(l:table.stringify(), {
                \ 'moved': 'any',
                \ 'height': str2nr(len(l:content)),
                \ })
endfunction
