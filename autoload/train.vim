scriptencoding utf-8

" import vital modules
let s:V = vital#train#new()
let s:HTTP = s:V.import('Web.HTTP')
let s:TABLE = s:V.import('Text.Table')
let s:DATE = s:V.import('DateTime')
let s:HTML = s:V.import('Web.HTML')

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

function! train#route_search(from, to) abort
    let l:url = 'https://transit.yahoo.co.jp/search/result?from=' .. a:from .. '&to=' .. a:to .. ''
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
                        let fee = attr_fare[0].value()

                        " 乗り換え回数
                        let transfer = attr_transfer[0] .. attr_transfer[1].value()

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

    let s:last_popup = popup_create(l:table.stringify(), {
                \ 'moved': 'any',
                \ 'title': l:title,
                \ })
endfunction
