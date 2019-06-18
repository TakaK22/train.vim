scriptencoding utf-8

" import vital modules
let s:V = vital#train#new()
let s:HTTP = s:V.import('Web.HTTP')
let s:TABLE = s:V.import('Text.Table')
let s:DATE = s:V.import('DateTime')
let s:HTML = s:V.import('Web.HTML')

let s:last_popup = 0
let s:current_window = 0
let s:result_window = "RESULT"

" create window
" when window is already created then use it
function! s:create_window(...) abort
    if a:0 < 1
        return
    endif

    let s:current_window = bufnr("%")

    if !bufexists(s:result_window)
        " create new buffer
        execute "new" s:result_window
    else
        " focus translate window
        let bid = bufnr(s:result_window)
        if empty(win_findbuf(bid))
            execute "new | e" s:result_window
        endif
        call s:focus_window(bid)
    endif

    setlocal buftype=nofile
    silent % d _

    let l:idx = 1
    for content in a:000
        call setbufline(bufname("%"), l:idx, content)
        let l:idx += 1
    endfor
endfunction

" focus window by buffer id
function! s:focus_window(bid) abort
    if !empty(win_findbuf(a:bid))
        call win_gotoid(win_findbuf(a:bid)[0])
    endif
endfunction

" train late info
function! train#late_info() abort
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

    if has("patch-8.1.1561")
        call popup_close(s:last_popup)
        let s:last_popup = popup_create(l:table.stringify(), {
                    \ 'moved': 'any',
                    \ 'height': str2nr(len(l:content)),
                    \ })
    else
        call s:create_window(l:table.stringify())
        call s:focus_window(bufnr(s:current_window))
    endif
endfunction

" train route search
function! train#route_search(...) abort
    if a:0 < 2
        echohl ErrorMsg
        echo '引数が不足しています。'
        echohl None
        return
    endif

    let l:from = a:1
    let l:to = a:2

    let l:url = 'https://transit.yahoo.co.jp/search/result?flatlon=&fromgid=&from=' .. l:from .. '&tlatlon=&togid=&to=' .. l:to .. '&viacode=&via=&viacode=&via=&viacode=&via=&type=1&ticket=ic&expkind=1&ws=3&s=0&al=1&shin=1&ex=1&hb=1&lb=1&sr=1&kw=' .. l:to
    let l:response = s:HTML.parseURL(l:url)

    let l:title =  l:response.find('title').value()

    let l:table = s:TABLE.new({
                \ 'columns': [{}, {}, {}, {}, {}],
                \ 'header': ['時刻', '乗車時間', '料金', '乗換回数', '']
                \ })

    for ul in l:response.findAll('ul')
        for li in ul.findAll('li')
            let dl = li.find('dl')
            if !empty(dl)
                let dd = dl.find('dd')
                if !empty(dd)
                    let ul = dd.find('ul')
                    if !empty(ul)
                        for li in ul.findAll('li')
                            if has_key(li.attr, "class")
                                let class = li.attr["class"]
                                if  class == "time"
                                    let attr_time = li.child
                                elseif class == "fare"
                                    let attr_fare = li.child
                                elseif class == "transfer"
                                    let attr_transfer = li.child
                                elseif class == "priority"
                                    let attr_priority = li.child
                                endif
                            endif
                        endfor

                        " 時刻と乗車時間
                        let attr_time_len = len(attr_time)
                        let start2end_time = ""
                        for attr in attr_time[:attr_time_len-2]
                            if type(attr) == type({})
                                let start2end_time .= attr.value()
                            else
                                let start2end_time .= attr
                            endif
                        endfor
                        let take_time = attr_time[attr_time_len-1].value()

                        " 料金
                        if type(attr_fare[0]) == type({})
                            let fee = attr_fare[0].value()
                        else
                            let fee = attr_fare[0]
                        endif

                        " 乗り換え回数
                        if len(attr_transfer) == 1
                            let transfer = attr_transfer[0]
                        else
                            let transfer = attr_transfer[0] .. attr_transfer[1].value()
                        endif

                        " 料金の安い順
                        let priority = ""
                        for p in attr_priority
                            let priority .= p.value()
                        endfor

                        call l:table.add_row([
                                    \ start2end_time,
                                    \ take_time,
                                    \ fee,
                                    \ transfer,
                                    \ priority,
                                    \ ])
                    endif
                endif
            endif
        endfor
    endfor

    if has("patch-8.1.1561")
        call popup_close(s:last_popup)
        let s:last_popup = popup_create(l:table.stringify(), {
                    \ 'moved': 'any',
                    \ 'title': l:title,
                    \ })
    else
        call s:create_window(l:title, l:table.stringify())
        call s:focus_window(bufnr(s:current_window))
    endif
endfunction
