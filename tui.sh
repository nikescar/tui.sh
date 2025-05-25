#!/usr/bin/env bash
#
# tui.sh - tui manager for bash. code taken from Torque by dylanaraps.
# https://github.com/dylanaraps/torque
# https://github.com/dylanaraps/pure-bash-bible
# working on bash 4.0+
# 
# * before release : parse tui.ex.yaml properly for yaml parse.
# * multiple cmd line.
# * logfile support.
# * category/selection/mode support.
#
# * feature : redirect main output to .tui_backfile and debug file
TUI_SH_VERSION=0.0.1

LC_ALL=C && LANG=C # for speedup

MIN_BASH_VERSION=4 # https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
[[ "${BASH_VERSINFO[0]:-0}" -lt "${MIN_BASH_VERSION}" ]] && echo "Bash Version > 4.0 Required." && exit 1

unameOut="$(uname -s)"
machine="UNKNOWN"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS_NT*)   machine=Git;;
    *)          machine="UNKNOWN:${unameOut}"
esac

BUSYBOX=""
[[ 1 -lt "$(sed --version|grep version|wc -l)" ]] && BUSYBOX="busybox.exe "
PGREP="ps ax|grep " # Linux
# [[ "MinGw" = "${machine}" || "Cygwin" = "${machine}" || "Git" = "${machine}" ]] && PGREP="ps ax|grep "

_regex() { # Usage: _regex "string" "regex"
    
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[@]}"
}

_trim_string() { # Usage: _trim_string "   example   string    "
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

_rstrip() { # Usage: _rstrip "string" "pattern"
    printf '%s\n' "${1%%$2}"
}

_hpurge() {
    [[ ${#tui_run_dir} -gt 0 ]] && rm -f ${tui_run_dir}/tui.access.hashmap.*
}

_hinit() {
    [[ ${#tui_run_dir} -gt 0 ]] && rm -f ${tui_run_dir}/tui.access.hashmap.$1
}

_hdel() {
    [[ ${#tui_run_dir} -gt 0 ]] && ${BUSYBOX}sed -i "/^$2\ /d" ${tui_run_dir}/tui.access.hashmap.$1
}

_hput() {
    [[ ${#tui_run_dir} -gt 0 ]] && echo "$2 $3" >> ${tui_run_dir}/tui.access.hashmap.$1
}

_hget() {
    [[ ${#tui_run_dir} -gt 0 ]] && grep "^$2" ${tui_run_dir}/tui.access.hashmap.$1 | awk '{ print $2 };'
}

_hcollect() {
    [[ ${#tui_run_dir} -lt 1 ]] && return 0 
    text=""
    for((i=0;i<=$2;i++)){
        tmp=$(printf "%05.f" $i)
        text="${text}$(grep "^$tmp " ${tui_run_dir}/tui.access.hashmap.$1 | awk '{ print $2 };')"
    }
    echo "${text}"
}

_refresh() {
    printf '\e[?7l\e[?25l\e[2J\e[H'
    shopt -s checkwinsize; (:;:)
    [[ -z "$LINES" ]] && read -r LINES COLUMNS < <(stty size)
}

_status_menu() {
    printf '\e[2m\e[%s;H%s\e[m' "$((LINES-1))" "$1"
}

_status_desc() {
    printf '\e[2m\e[%s;H%s\e[m' "$((LINES-2))" "$1"
}

_tprint() {
    printf '%s\e[K\e[2m\e[m \e[1m\e[\e[m\n' "$1" 
}

_tui_log() { # _tui_log 1/2/3/4/5 "log msg" # ALL > TRACE > DEBUG > INFO > WARN > ERROR > FATAL > OFF
    if [[ "${loglv}" -lt "${1}" ]]; then
        local level="TRACE"
        case "$1" in
            0) level="ALL" ;;
            1) level="TRACE" ;;
            2) level="DEBUG" ;;
            3) level="INFO" ;;
            4) level="WARN" ;;
            5) level="ERROR" ;;
            6) level="FATAL" ;;
            7) level="OFF" ;;
        esac
        local prefix="${TUISH_LOG_PREFIX:-default}"
        local message="${level%: }: ${prefix%: }: ${2?}"
        printf '%s\n' "${message}" >> "${dbgfile_str}" 
    fi
}

_main_get_conf() {
    local TUISH_LOG_PREFIX="_main_get_conf" # debug prefix
    # lines, dot_idt
    local tui_config_level=0
    for((j=1;j<${#lines[@]};j++)){ # check
        lot_line_j="$(_trim_string "${lines[j]}")"
        IFS=$'\n' read -d "" -ra tmp <<< "${lot_line_j//:/$'\n'}" 
        local lot_key_j="${tmp[0]}" && local lot_val_j="$(IFS=:; echo "${tmp[*]:1}")"
        tmp="${lines[j]/[^[:space:]]*/}" && lot_idt_j=${#tmp}
        lot_lv_j=$(( lot_idt_j / doc_idt ))

        # tui configurations 
        [[ "${lot_key_j}" = "_tui_sh_config" ]] && tui_config_level="$(_trim_string "${lot_lv_j}")"
        [[ "${lot_key_j}" = "tui_httpd_bin" ]] && tui_httpd_bin="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_caddy_cmd" ]] && tui_caddy_cmd="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_darkhttpd_cmd" ]] && tui_darkhttpd_cmd="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_web_dir" ]] && mkdir -p ${lot_val_j} && tui_web_dir="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_log_dir" ]] && mkdir -p ${lot_val_j} && tui_log_dir="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_binding_ip" ]] && tui_binding_ip="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_posting_address" ]] && tui_posting_address="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_web_port" ]] && tui_web_port="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_basic_auth" ]] && tui_basic_auth="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_run_dir" ]] && mkdir -p ${lot_val_j} && tui_run_dir="$(_trim_string "${lot_val_j}")"
        [[ "${lot_key_j}" = "tui_net_dir" ]] && mkdir -p ${lot_val_j} && tui_net_dir="$(_trim_string "${lot_val_j}")"
        # todo : scan for _globalkeycode
        [[ -z ${lot_key_j} ]] && continue
        _tui_log 0 "$LINENO: ${tui_config_level}/${lot_lv_j} : ${lot_key_j}" 
        # [[ $tui_config_level -gt 0 && $lot_lv_j -le $tui_config_level ]] && break # sibling or parent occur stop
    }
}

_main_get_block() { # yaml parser
    local TUISH_LOG_PREFIX="_main_get_block" # debug prefix
    local blk_idt="" # serialize cmds, current indent
    # blk_ilink=() && blk_clink=() # current internet link open with $BROWSER, current local link
    local blk_prnts=() # traverse cache for parent
    # blk_seltree=() # selection tree
    local blk_start=0 && local blk_end=0 # start line number, end line number
    # rotating info - before block info filled
    local lot_idt=0
    local lot_lv=0
    # C1. case of menu(not attribute)
    # 1. check if valid menu(keycode in subs exists)
    # 2. fill parent info
    # 3. find starting line
    # 4. get submenu
    # C2. case of attribute
    # 1. get _keycode, _description, _cmd
    # *. _glocalkeycode search
    _tui_log 2 "$LINENO: START SCANNING YAML FOR : ${srq_addr}"  
    # get doc from lines
    for((i=0;i<${#lines[@]};i++)){ 
        trimed_line=$(_trim_string ${lines[i]})
        [[ "---" = $trimed_line ]] && continue # skip first line ---
        [[ -z $trimed_line ]] && continue # skip blank line 
        # configurations on level 0, todo: scan for global_keycode only on lv0 #

        # get current level by counting leading spaces
        local lot_line="" && lot_line="${lines[i]}"
        [[ " " != "${lot_line[i]}" ]] && tmp=${lotline[$((i+1))]} && tmp="${tmp/[^[:space:]]*/}" && lot_idt=${#tmp}
        _tui_log 0 "$LINENO: lot_idt : $lot_idt "  
        [[ $lot_idt = 0 ]] && tmp="${lot_line/[^[:space:]]*/}" && lot_idt=${#tmp}
        _tui_log 0 "$LINENO: lot_idt : $lot_idt "  
        [[ $lot_idt = 1 ]] && doc_idt=1 # in case indent 1, doc indent is 1
        [[ $lot_idt != 0 ]] && lot_lv=$(( lot_idt / doc_idt + 1 )) || lot_lv=1

        _tui_log 0 "$LINENO: line : "${i}", lot_idt : ${lot_idt}, doc_idt : ${doc_idt} "                
        _tui_log 0 "$LINENO: blk_start : ${blk_start}, blk_end : ${blk_end}, srq_lv : ${srq_lv}, lot_lv : ${lot_lv} " 
        # check end approach
        [[ $blk_start != 0 && $blk_end = 0 && $srq_lv -ge $lot_lv ]] && blk_end=$i && _tui_log 2 "$LINENO: FOUND MATCHING END LINE AT : ${i}" && break # stop search FOR->I

        # parse string
        lot_line=$trimed_line
        IFS=$'\n' read -d "" -ra tmp <<< "${trimed_line//:/$'\n'}" # split
        local lot_key="${tmp[0]}" && lot_key=$(_trim_string "${lot_key}")
        local lot_val="${tmp[1]}" && lot_val=$(_trim_string "${lot_val}")
        _tui_log 0 "$LINENO: srq_lv : ${srq_lv}, lot_lv : ${lot_lv}, srq_name : ${srq_name}, lot_key : ${lot_key}, blk_addr : ${blk_addr}, srq_addr : ${srq_addr}, blk_lv : ${blk_lv}, lot_lv : ${lot_lv}"
        
        # 2.fill parent traverse, #3.finding start line
        [[ $blk_start = 0 && ${lot_key:0:1} != '-' ]] && blk_prnts[lot_lv]=$lot_key 
        # set block name, address for matching srq root 
        [[ $srq_lv = "${lot_lv}" && $srq_name = "${lot_key}" ]] && blk_name=$lot_key && blk_addr=$srq_addr && blk_lv=$lot_lv \
            && _tui_log 2 "$LINENO: FOUND MATCHING START LINE AT : ${i}" && blk_start=$i && continue # skip FOR->I
        _tui_log 0 "$LINENO: i : ${i}, lot_lv : ${lot_lv}, srq_lv : ${srq_lv}, srq_name : $srq_name, lot_key : ${lot_key}" 

        # skip non-direct ansestary
        [[ $lot_lv != $(( srq_lv+1 )) ]] && continue

        # check whether skip subsection
        local skip_subsection=0
        # C1. case of menu(not attribute)
        if [[ $lot_key != _* && $lot_key != -* && -n $lot_key ]]; then 
            #1.search for keycode in subtree
            local j=$(( i + 1 ))
            local lot_keycode=""
            _tui_log 2 "$LINENO: START SCANNING SUBTREE FOR MENU KEYCODE FOR : ${lot_key}"
            for((j=i+1;j<${#lines[@]};j++)){ # check child nodes for _keycode
                lot_line_j="$(_trim_string "${lines[j]}")"
                [[ ${lot_line_j:0:8} != "_keycode" ]] && continue # look for _keycode FOR->J

                IFS=$'\n' read -d "" -ra tmp <<< "${lot_line_j//:/$'\n'}" # split
                local lot_key_j="${tmp[0]}" && local lot_val_j="${tmp[1]}"
                _tui_log 0 "$LINENO: lot_key_j: ${lot_key_j}, lot_val_j : ${lot_val_j}"
                tmp="" && for((k=0;k<$(( lot_idt+doc_idt*1 ));k++)){ tmp=$tmp$(printf " %.0s"); }
                _tui_log 0 "$LINENO: lot_key_j : ${lot_key_j}, tmp : ${#tmp}, lot_line_j: ${lines[j]} keycode: ${tmp}_keycode"
                [[ ${lines[j]} = "${tmp}_keycode"* ]] && lot_keycode=$(_trim_string ${lot_val_j}) && _tui_log 0 "$LINENO: FOUND KEYCODE : ${lot_keycode}" && break # found keycode, stop FOR->J
                # check end
                tmp="${lines[j]/[^[:space:]]*/}" && lot_idt_j=${#tmp}
                lot_lv_j=$(( lot_idt_j / doc_idt ))
                _tui_log 0 "$LINENO: lot_key: ${lot_key}, lot_lv_j : ${lot_lv_j}, lot_lv : ${lot_lv}"
                [[ $lot_lv_j -le $lot_lv ]] && break # sibling or parent occur stop FOR->J
            }
            
            #1.check keycode in menu name & build control name
            _tui_log 2 "$LINENO: CHECK MENU HAS VALID KEYCODE FOR : ${lot_key}"
            [[ $blk_start -gt 0 && -n $lot_keycode ]] && tmp="" && local marked="" \
                && for((j=0;j<${#lot_key};j++)){
                    if [[ $lot_keycode = "${lot_key:j:1}" && $marked = "" ]];then 
                        tmp="${tmp}[${lot_key:j:1}]" && marked="1";
                        _tui_log 2 "$LINENO: FOUND KEYCODE IN MENU : ${tmp}"
                    else
                        tmp="${tmp}${lot_key:j:1}"
                        # _tui_log 2 "$LINENO: KEYCODE IN MENU NOT FOUND : ${tmp}"
                    fi
                    _tui_log 0 "$LINENO: lot_keycode: ${lot_keycode}, lot_key[j]: "${lot_key:j:1}", tmp : ${tmp}, len : ${#tmp}"
                } && [[ -n $marked ]] && blk_subms+=($tmp)
            continue
        fi
        [[ $blk_start = 0 ]] && _tui_log 2 "$LINENO: START LINE NOT FOUND FOR : ${srq_addr} AT ${i}" && continue # skip if starting point not found

        # C2 case of attribute
        # 3. get _description, _cmd
        # val types : string, int, arr[], arr-$
        _tui_log 0 "$LINENO: line = "${i}", lot_key: ${lot_key}, lot_val: ${lot_val}"
        local does_cmd_Sarr=0
        case "${lot_key}" in
            "_description"*)
                blk_descs=${lot_val}
            ;;
            "_cmd"*)
                # case of string& int, counting nextline indent
                # todo: change capture from sed
                tmp="${lines[i+1]/[^[:space:]]*/}"
                nl_cnt=${#tmp}
                # _tui_log 0 "$LINENO: line: "${lines[i+1]}", spaces: ${nl_cnt}, tmp: ${tmp}" 
                [[ $nl_cnt != 0 ]] && nl_lv=$(( nl_cnt / doc_idt )) # nextline lv
                [[ $nl_lv -le $lot_lv && -n $lot_val ]] && blk_cmd+=" && ($lot_val)" && continue 

                # case of [] Barray
                # todo: implement
                [[ ${lot_val:1:2} = "[" ]] && echo "line number ${i} has [] style array. tui.sh doesn't support yet. please change it to single line array."  && exit 1

                # case of -.*$ Sarray
                does_cmd_Sarr=1
                # _tui_log 0 "$LINENO: does_cmd_Sarr = ${does_cmd_Sarr}"
                _tui_log 2 "$LINENO: FOUND _CMDS : ${#blk_cmd}"
            ;;
        esac
        # cmd Sarray gather
        [[ $does_cmd_Sarr = 1 ]] \
            && for((j=i+1;j<${#lines[@]};j++)){ # check
                tmp="${lines[j]/[^[:space:]]*/}" && lot_idt_j=${#tmp}
                lot_lv_j=$(( lot_idt_j / doc_idt ))
                _tui_log 0 "$LINENO: lot_lv_j: ${lot_lv_j}, lot_lv: ${lot_lv}"
                [[ $lot_lv_j -lt $lot_lv ]] \
                    && break # sibling or parent occur stop

                lot_line_j="$(_trim_string "${lines[j]}")"
                # blk_cmd+=(${lot_line_j:1}) # can't be array
                blk_cmd+=" && (${lot_line_j:1})"
                # skip subsection
                skip_subsection=$(( j-1 ))
            }

        [[ $skip_subsection -gt 0 ]] && i=$skip_subsection # cmd section & 
    }

    # take out
    #blk_start blk_end blk_name blk_lv blk_addr 
    #blk_subms blk_descs blk_cmd
    _tui_log 2 "$LINENO: PARSED FOR ${blk_start}-${i}: ${blk_addr} ${blk_name}(${blk_lv}) "
    _tui_log 2 "$LINENO: PARSED blk_subms : "$(IFS=:; echo "${blk_subms[*]}")""
}

_main_get_output() { # print output from back screen file
    local TUISH_LOG_PREFIX="_main_get_output" # debug prefix
    # safe pididx
    if [[ $pididx -ge ${#pidshist[@]} && $pididx -gt 0 ]]; then pididx=${#pidshist[@]} & pididx=$(( pididx - 1 )); fi 
    if [[ $pididx -lt 0 ]]; then pididx=0; fi
    local pidfn=${pidshist[$pididx]} && tmp="" # pid.tui_219302390390
    tmp=${pidfn/[0-9]*\./} # check tmp pid file exists, tui_2939191239830
    pid=${pidfn/\."${tmp}"/} # get pid
    [[ -f "${tui_run_dir}/.${tmp}" ]] && tmp="${tui_run_dir}/.${tmp}" # check if tmp file exists
    [[ -f "${tui_run_dir}/${pid}" ]] && tmp="${tui_run_dir}/${pid}" # check pid file exists
    [[ -n $tmp ]] && IFS=$'\n' mapfile -tn 0 t < <(tail -n "$((LINES * 10))" "${tmp}") # get screen file
    [[ -z $tmp ]] && t=("")
    local header="" && [[ ${#t[@]} -gt 1 ]] && header="L$(head -n 1 "${tmp}")"
    unset 't[0]' 't[-1]' 2>/dev/null

    local scr_tl=${#t[@]} # total lines to print
    local scr_n=$(( LINES-4 )) # lines in tty screen
    local scr_tn=$(( scr_tl / scr_n )) # total pages

    local scr_k=0 # show line start
    local scr_j=0 # show line end

    # safe p
    [[ $p -lt 0 ]] && p=0
    [[ $p -gt $scr_tn ]] && p=$scr_tn
    [[ $m = "at" ]] && p=$scr_tn # mode check
    # attach mode
    if [[ $p = "${scr_tn}" ]]; then
        scr_k=$(( scr_tl - scr_n )) && [[ $scr_k -lt 0 ]] && scr_k=0 # start point
        scr_j=$(( scr_k + scr_n )) && [[ $scr_j -gt $scr_tn ]] && scr_j=$scr_tl # end point
        p=$scr_tn
        m="at"
    else # detach mode tl-50 n-10 t-5 p-4 k=30 j=40
        scr_k=$(( scr_tl - ( scr_n * ( scr_tn - p + 1 ) ) ))
        [[ $scr_k -lt 0 ]] && scr_k=0
        scr_j=$(( scr_k + scr_n ))
    fi
    # print screen
    for((i=scr_k;i<=scr_j;i++)){
        [[ ${t[i]} = "0" ]] && continue
        _tprint "${t[i]/n\/a/0}";
    }
    local ready=""
    local wspaces='                                                                                                                                                                                    '
    local pidrun=$(echo "${pidsrun[@]/${pid}//}"| cut -d/ -f1 | wc -w | tr -d ' ')
    if [[ -n "${pidsrun[$pidrun]}" ]]; then pid=${pidsrun[$pidrun]}; else pid=""; fi 
    _tui_log 0 "$LINENO: pididx : "${pididx}", pidsrun : "$(IFS=:; echo "${pidsrun[*]}")", pid : "${pid}", pidrun : "${pidrun}", pidshist : "$(IFS=:; echo "${pidshist[*]}")","
    [[ ${#pidshist[@]} -gt 0 ]] && tmp=$((pididx + 1)) || tmp=0
    [[ -z "${pid}" ]] && ready="[C]lose<done>[Up/Down](${tmp}/${#pidshist[@]})" || ready="[K]ill<${pid}>[Up/Down](${tmp}/${#pidshist[@]})" # show pid
    local mproc_memnu="$ready"
    tmp=$(expr ${COLUMNS} - ${#mproc_memnu})
    local proc_menu="[j/k]("$(( p + 1 ))"/"$(( scr_tn + 1 ))") $(IFS=" "; echo "${blk_descs}")"
    [[ -z "${pid}" ]] && proc_menu="[j/k]("$(( p + 1 ))"/"$(( scr_tn + 1 ))") ${header}"
    [[ $tmp -lt ${#proc_menu} ]] && proc_menu="${proc_menu:0:$((tmp-3))}.. " # cut if oversize
    tmp=$(expr ${COLUMNS} - ${#proc_menu} - ${#mproc_memnu})
    [[ $tmp -lt 4 ]] && tmp=4
    _status_desc "${proc_menu}${wspaces:0:$tmp}${mproc_memnu}"$'\e[K\e[H' # show current menu description
    _tui_log 0 "$LINENO: scr_k : ${scr_k}, scr_j : ${scr_j}, p : ${p}, scr_tn : ${scr_tn}, scr_tl : ${scr_tl}, m : ${m}"

    [[ $blk_lv -gt 1 ]] && tmp="[u]p" || tmp="" # show up control
    local sticky_menu="${tmp} [q]uit "
    tmp="[t]web(disabled)"
    [[ -n $pid_web ]] && tmp="[t]web(http://${tui_binding_ip}:${tui_web_port})" 
    sticky_menu="${sticky_menu}${tmp}"
    local dynamic_menu="L${blk_lv}:${blk_name}> ${blk_subms[*]}"
    tmp=$(expr ${COLUMNS} - ${#sticky_menu})
    [[ $tmp -lt ${#dynamic_menu} ]] && dynamic_menu="${dynamic_menu:0:$((tmp-3))}.. " # cut if oversize
    tmp=$(expr ${COLUMNS} - ${#sticky_menu} - ${#dynamic_menu})
    [[ $tmp -lt 4 ]] && tmp=4
    _status_menu "${dynamic_menu}${wspaces:0:$tmp}${sticky_menu}"$'\e[K\e[H'
    _tui_log 0 "$LINENO: COLUMNS: ${COLUMNS}, sticky_menu: ${#sticky_menu}, dynamic_menu: ${#dynamic_menu}, tmp: ${tmp}"
}

_main_exit() { # onexit function
    local TUISH_LOG_PREFIX="_main_exit" # debug prefix
    for tpid in "${pidsrun[@]}"; do [[ ! $(test -d /proc/$tpid/) ]] && kill -9 $tpid &>/dev/null ; done  # kill running procs
    for tpid in "${pidsrun[@]}"; do rm -f "${tui_run_dir}/${tpid}" &>/dev/null; done  # remove procs screen
    for hpid in "${pidshist[@]}"; do tmp=${hpid/[0-9]*\./};rm -f "${tui_run_dir}/.${tmp}";tmp=${hpid/\.${tmp}/};rm -f "${tui_run_dir}/${tmp}" &> /dev/null; done 
    for fifof in "${fifohist[@]}"; do rm -f "${tui_run_dir}/${fifof}" &> /dev/null; done 
    rm -f ${tui_run_dir}/.tui_* &>/dev/null
    rm -f ${tui_net_dir}/* &>/dev/null
    [[ -n $pid_web ]] && kill -9 $pid_web &>/dev/null # exit httpd
    rm -f ${tui_run_dir}/tui.access.log &>/dev/null
    rm -f ${tui_run_dir}/tui.access.hashmap.* &>/dev/null
    [[ -n $pid_resp ]] && kill -9 $pid_resp &>/dev/null # exit respond
    printf '\e[?25h\e[?7h\e[999B' # clear screen
}

_prompt_server_flip(){
    [[ ! -f ./.tui_web/index.html ]] && _main_prep_tuiweb
    local TUISH_LOG_PREFIX="_prompt_server_flip" # debug prefix
    _tui_log 0 "$LINENO: tui_httpd_bin: ${tui_httpd_bin}, pid_web: ${pid_web}, tui_httpd_bin: ${tui_httpd_bin}"
    _tui_log 2 "tui_web bin executable found : $(type ${tui_httpd_bin})"
    if [[ $(type ${tui_httpd_bin} 2>/dev/null) ]]; then
        tmp=$tui_caddy_cmd && [[ $tui_httpd_bin = "darkhttpd" ]] && tmp=$tui_darkhttpd_cmd
        [[ $tmp == *"{{ tui_web_dir }}"* ]] && tmp=${tmp//"{{ tui_web_dir }}"/${tui_web_dir}}
        [[ $tmp == *"{{ tui_log_dir }}"* ]] && tmp=${tmp//"{{ tui_log_dir }}"/${tui_log_dir}}
        [[ $tmp == *"{{ tui_run_dir }}"* ]] && tmp=${tmp//"{{ tui_run_dir }}"/${tui_run_dir}}
        [[ $tmp == *"{{ tui_net_dir }}"* ]] && tmp=${tmp//"{{ tui_net_dir }}"/${tui_net_dir}}
        [[ $tmp == *"{{ tui_binding_ip }}"* ]] && tmp=${tmp//"{{ tui_binding_ip }}"/${tui_binding_ip}}
        [[ $tmp == *"{{ tui_posting_address }}"* ]] && tmp=${tmp//"{{ tui_posting_address }}"/${tui_posting_address}}
        [[ $tmp == *"{{ tui_web_port }}"* ]] && tmp=${tmp//"{{ tui_web_port }}"/${tui_web_port}}
        [[ $tmp == *"{{ tui_basic_auth }}"* ]] && tmp=${tmp//"{{ tui_basic_auth }}"/${tui_basic_auth}}
        _tui_log 0 "$LINENO: "${PGREP}"$tui_httpd_bin|grep "${tui_web_port}"|cut -d" " -f1"
        pid_web=$(${PGREP} ${tui_httpd_bin}|grep ${tui_web_port}|cut -d" " -f1)
        if [[ -z $pid_web ]]; then
            cp -f "${yamlfn_str}" "${tui_web_dir}/index.yaml" &>/dev/null # update yaml file
            ${tmp} 2>./tui_web.debug.log & # run httpd
            pid_web=$!
            [[ -z $pid_web ]] && _tui_log 4 "tui_web running process cannot run."
            _tui_log 2 "tui_web : ${tmp}"
            _tui_log 2 "tui_web initiated with pid : ${pid_web}"
            ${0} -m tui_web_respond &>./tui_web_respond.log & # run tui respond
            pid_resp=$!
            [[ -z $pid_resp ]] && _tui_log 4 "tui_web_respond cannot run."
            _tui_log 2 "tui_web_respond with pid : ${pid_resp}"
        else
            kill -9 "${pid_web}" &>/dev/null; pid_web=""
            _tui_log 2 "tui_web killed with pid : ${pid_web}"
            kill -9 "${pid_resp}" &>/dev/null; pid_resp=""
            _tui_log 2 "tui_web_respond killed with pid : ${pid_resp}"
            rm -f "${tui_run_dir}/tui.access.log"
            rm -f "${tui_run_dir}/tui.access.hashmap.*"
        fi
        _tui_log 0 "$LINENO: pid_web: ${pid_web}"
    else # no httpd found
        _tui_log 4 "no ${tui_httpd_bin} httpd binaries exists. "
    fi
}

_main_prep_tuiweb(){
    local TUISH_LOG_PREFIX="_main_prep_tuiweb" # debug prefix
    tar zxvf tui_web.tar.gz --strip-components 1 -C .tui_web/ &>/dev/null
    cp -rf ${yamlfn_str} .tui_web/index.yaml &>/dev/null

    echo "tui_web.tar.gz is extracted to ./.tui_web."
    echo "${yamlfn_str} has copyed to ./.tui_web/index.yaml."
}

prompt() { # keyboard event handler
    _status_menu $'\e[B\e[?25h'
    _status_desc $'\e[B\e[?25h'
    # if [u]p keypressed
    [[ $1 = "u" && $spawn = 0 && $blk_lv != 1 ]] \
        && srq_addr=$(_rstrip $blk_addr "/${blk_name}") && spawn=1 && sp=0
        _tui_log 0 "$LINENO: [u]p => srq_addr: {$srq_addr}"
    # arrow keys
    # enter keys
    # if submenu keypressed
    for((i=0;i<${#blk_subms[@]};i++)){
        menu=${blk_subms[i]}
        # if [[ $pid = 0 ]]; then # process ended
        _tui_log 0 "$LINENO: blk_addr: "${blk_addr}", menu: "${menu}""
        [[ $menu == *\[$1\]* && $spawn = 0 ]] && srq_addr="${blk_addr}/${menu//[\]\[]}" && spawn=1 && sp=0  # sub
        # fi
    }
    # arrow up([A)/down([B) key for process screen shift
    # arrow left([C)/right([D) for menu selection 
    case "$1" in
        # $'\x09') _tui_log 1 "TAB pressed!"; ;; # TAB
        # $'\x7f') _tui_log 1 "Back Space pressed!"; ;; # Back-Space
        # $'\x01') _tui_log 1 "Ctrl A pressed!"; ;; # Ctrl+A
        \[) read -rsN1; [[ "$REPLY" = "A" ]] && pididx=$(( pididx + 1)) ; [[ "$REPLY" = "B" ]] && pididx=$(( pididx - 1))  ;;
        C) pidfn=${pidshist[$pididx]};tmp=${pidfn/[0-9]*\./};tmp=${pidfn/\."${tmp}"/};rm -f ${tui_run_dir}/$tmp &>/dev/null; unset -v 'pidshist[$pididx]'; ;; # remove from pidshist
        K) kill -9 ${pid} &>/dev/null;  ;; # kill pid and remove from pidshist
        t) _prompt_server_flip ;; # tui_web toggle 
        j) p=$(( p - 1 )) && m="dt" && sp=0 ;; # page up
        k) p=$(( p + 1 )) && m="dt" && sp=0 ;; # page down
        q) exit 0 ;; # quit
        # *) _tui_log 2 "$1" ;;
    esac
    [[ "$1" =~ (j|k) ]] || _refresh && printf '\e[?25l\e[H'
    # _tui_log 1 "pid : ${pidshist[$pididx]}, pidshist# : ${#pidshist}"
}

main() {
    local TUISH_LOG_PREFIX="main" # debug prefix
    local tui_caddy_cmd="caddy run --config Caddyfile {{ tui_web_port }}"
    local tui_darkhttpd_cmd="darkhttpd {{ tui_web_dir }} --no-keepalive --addr {{ tui_binding_ip }} --port {{ tui_web_port }} --maxconn 4 --log {{ tui_run_dir }}/tui.access.log --no-server-id --no-listing --auth {{ tui_basic_auth }}"
    # configurations vars
    local tui_httpd_bin="darkhttpd" # or caddy
    local tui_web_dir="./.tui_web" && local tui_log_dir="./.tui_web/var/log" && local tui_run_dir="./.tui_web/var/run" && local tui_net_dir="./.tui_web/var/net"
    local tui_binding_ip="127.0.0.1" && local tui_posting_address="localhost" && local tui_web_port="58080" && local tui_basic_auth="test:test"
    local tui_access_log="access.log"
    # backgound proc page control
    p=0 # cur page no.
    m="at" # dt - detached, at - attached
    spawn=1 # 1 - spawn, 0 - non spawn
    sp=0 # 0 - screen refresh paused, ##### - screen refresh active pid
    pid=0 # master subprocessor on back screen
    pididx=0 # cur pid page no.
    pidsrun=() # current running proccesses on background
    pidshist=() # pids history
    pid_web="" # pid for tui_web
    pid_resp="" # pid for tui_web_respond
    fifohist=() # fifo history file

    local doc_idt=2 # default single indentation
    local srq_addr="${root_str}" # selected address
    local srq_global_keycode=("ctrl+r:/") # global keycode
    
    # get configurations from yaml
    IFS=$'\n' read -rd '' -a lines <<<"$yaml_str"
    _main_get_conf # from lines
    # tui_web mode. run and exit.
    [[ "tui_web" = "${mode_str}" ]] && \
        if [[ -z $(${PGREP}${tui_httpd_bin}|grep ${tui_web_port}|cut -d" " -f1) ]]; then
            _prompt_server_flip && echo "server has started on http://${tui_binding_ip}:${tui_web_port}" && exit 0
        else
            echo "${tui_web_port} port is busy" && exit 1
        fi
    _refresh
    trap _main_exit EXIT
    trap '_refresh; k=0' SIGWINCH
    
    for ((;;)) # looping every second
    do
        if [ $spawn = 1 ]; then # entered in new menu.
            # block info - current screen
            # get block info(global) while searching
            blk_cmd=":" 
            blk_lv=0 && blk_name="" && blk_addr="" # current level, current menu name, address
            blk_descs="" && blk_subms=() # current descriptions, current submenus
            
            # query info - changed by user select
            tmp="${srq_addr//[^\/]}" # count slashes in search block address
            local srq_lv=${#tmp} && srq_lv=$(( srq_lv )) # put int current level number starting from 1
            local srq_name="" && srq_name="$(_regex "${srq_addr}" "\/[^\/]*$")" && srq_name="${srq_name:1}" # last part /name
            # local srq_idt="$(for((i=0;i<$(( srq_lv-1 ));i++)){ printf "$doc_idt%.0s"; })" # search query indent
            _tui_log 0 "$LINENO: ENTERING NEW MENU : (${blk_lv})${srq_addr}" 
            _main_get_block # get information on block
        fi
        for tpid in "${pidsrun[@]}"; do # check pids alive, remove from pidsrun if not running
            [[ ! $(test -d /proc/$tpid/) ]] \
                && pidsrun=("${pidsrun[@]/$tpid}") && tmp=$(echo "${pidshist[@]/$tpid//}"| cut -d/ -f1 | wc -w | tr -d ' ') \
                && [[ $tmp -lt ${#pidshist[@]} ]] && tmp=${pidshist[$tmp]} && tmp=${tmp/[0-9]*\./} \
                && mv "${tui_run_dir}/.${tmp}" "${tui_run_dir}/${tpid}"
        done
        pid_web=$(${PGREP}${tui_httpd_bin}|grep ${tui_web_port}|cut -d" " -f1) # check webserver is working
        [[ $sp -gt 0 ]] && [[ $(ps x|grep "${sp}"|wc -l) -le 1 ]] && sp=0 # check new proc stays on front
        if [ $spawn = 1 ]; then # spawn new proc.
            local srq_stdout=".tui_$(date +%s%N)" # fifo file
            echo -e "${srq_lv}:${srq_addr}> ${blk_descs}" >"${tui_run_dir}/${srq_stdout}"
            # replace runtime vars on cmd line.
            [[ $blk_cmd == *"{{ screenfile }}"* ]] && blk_cmd=${blk_cmd//"{{ screenfile }}"/"${tui_run_dir}/${srq_stdout}"}
            [[ $blk_cmd == *"{{ tty }}"* ]] && blk_cmd=${blk_cmd//"{{ tty }}"/${ttyid_str}}    

            [[ ${#blk_cmd} -gt 1  ]] \
                && eval "(printf '\n' && ${blk_cmd} && printf '\n\n') >>${tui_run_dir}/${srq_stdout} &" \
                && pid=$! && pidshist+=("${pid}${srq_stdout}") && pidsrun+=("${pid}") && pididx=${#pidshist[@]} && pididx=$(( pididx - 1 )) \
                && [[ $blk_cmd == *"${ttyid_str}"* ]] && sp=$pid

            spawn=0
        fi
        if [[ $sp = 0 ]]; then # stop screen refresh when ncurses app stays
            _main_get_output; read -rsN1 -t"$rtime_flt" && prompt "$REPLY" 
        fi
    done
}

single(){
    # get configurations
    local doc_idt=2
    local srq_addr="${root_str}"
    IFS=$'\n' read -rd '' -a lines <<<"$yaml_str"
    _main_get_conf # from lines

    # block info
    blk_cmd=":" 
    blk_lv=0 && blk_name="" && blk_addr="" # current level, current menu name, address
    blk_descs="" && blk_subms=() # current descriptions, current submenus
    
    # query info - changed by user select
    tmp="${srq_addr//[^\/]}" # count slashes in search block address
    local srq_lv=${#tmp} && srq_lv=$(( srq_lv )) # put int current level number starting from 1
    local srq_name="" && srq_name="$(_regex "${srq_addr}" "\/[^\/]*$")" && srq_name="${srq_name:1}" # last part /name
    _main_get_block
    
    [[ ${#blk_cmd} -gt 1  ]] && eval "(${blk_cmd})" && pid=$! 
}

# params https://stackoverflow.com/a/39376824
progname=$(basename "$0")
loglv=2
dryrun=0
yamlfn_str="./tui.sh.yaml"
root_str="/bkit"
dbgfile_str="./tui.debug.log"
rtime_flt=1.1 # screen refresh time 0.001 ~ 10 seconds
mode_str="tui"
batch_str=""
ttyid_str="$(tty)" # get current tty

# clear log
# echo "" > "${dbgfile_str}" 

# usage function
function usage()
{
   cat << HEREDOC

   Usage: $progname [--yaml YAMLFILE] [--root ROOTPATH] [--dbgfile DEBUGFILE] [--rtime TIMESECOND]
                    [--mode RUNTIMEMODE] [--batch BATCHNAME]
                    [--loglv] [--dry-run]

   optional arguments:
     -h, --help                 show this help message and exit
     -y, --yaml YAMLFILE        yaml file(default./tui.sh.yaml)
     -r, --root ROOTPATH        root path of the menu tree(default. /bkit)
     -b, --dbgfile DEBUGFILE    debug file path(default. ./tui.debug.log)
     -m, --mode RUNTIMEMODE     single or batch or tui(default. tui)
                                - single : only run a absolute root path and exit
                                - batch : find node matching attribute(_batch) name and run trough root path and exit
                                - tui : default tui mode
                                - tui_web : only tui_web listen mode
                                - tui_web_respond : parse access.log and run requested command. for internal usage
     -t, --rtime TIMESECOND     (tui mode) screen refresh time in float second(default. 1.1)
     -c, --batch BATCHNAME      (batch mode) predefined batch name on yaml file to run
     -v, --loglv                log level of the bash script. 1]DEBUG 2]INFO 3]WARN 4]ERROR
     --dry-run                  do a dry run, check only md file and exit

   examples:
     > ./tui.sh                   
      show tui menu from tui.sh.yaml root. run job selectively
     > ./tui.sh -m single -r /bkit/status/netstat
      run only cmd on /bkit/status/netstat and exit
     > ./tui.sh -m 

HEREDOC
}  

OPTS=$(getopt -o "hy:r:b:t:m:c:d:v:" --long "help,yaml:,root:,dbgfile:,rtime:,mode:,batch:,loglv:,dry-run," -n "$progname" -- "$@")
if [ $? != 0 ] ; then echo "Error in command line arguments." >&2 ; usage; exit 1 ; fi
eval set -- "$OPTS"

while true; do
    case "$1" in
        -h | --help ) usage; exit; ;;
        -y | --yaml ) yamlfn_str="$2"; shift 2 ;;
        -r | --root ) root_str="$2"; shift 2 ;;
        -d | --dbgfile ) dbgfile_str="$2"; shift 2 ;;
        -t | --rtime ) rtime_flt="$2"; shift 2 ;;
        -m | --mode ) mode_str="$2"; shift 2 ;; # 1]single 2]batch 3]tui 4]tui_web 5]tui_web_respond
        -c | --batch ) batch_str="$2"; shift 2 ;;
        -v | --loglv ) loglv="$2"; shift 2 ;; # 1)"DEBUG" 2)"INFO" 3)"WARN" 4)"ERROR" ;;
        --dry-run ) dryrun=1; shift ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

if [[ $loglv -lt 2 ]]; then   # print out all the parameters we read in
    cat <<EOM
    yaml=$yamlfn_str
    root=$root_str
    dbgfile=$dbgfile_str
    rtime=$rtime_flt
    mode=$mode_str # 1]single 2]batch 3]tui 4]tui_web 5]tui_web_respond
    batch_str=$batch_str
    dryrun=$dryrun
    loglv=$loglv # 1)"DEBUG" 2)"INFO" 3)"WARN" 4)"ERROR"
    ttyid=$ttyid_str
EOM
fi

# initial checking "$(_trim_string "${lines[j]}")"
[[ ! -f $yamlfn_str ]] && _tui_log 4 "yaml file ${yamlfn_str} not exsit." && exit 1 # check yaml file exists
yaml_str="$(cat "${yamlfn_str}" | ${BUSYBOX}sed -e 's/^---\(.*\)\.\.\./\1/')" # load tree from params
_tui_log 0 "yaml_str : ${yaml_str}"
yaml_str="$(echo "${yaml_str}" | ${BUSYBOX}sed -e 's/ # .*$//g')" # remove comment
_tui_log 1 "yaml_str : ${yaml_str}"
[[ -z ${yaml_str} ]] && echo "yaml file ${yamlfn_str} is empty"
# todo: multiline, flow, anchor, tag, block, doc stream in yaml v1.2

tmp="${root_str//[^\/]}" && tmp=${#tmp} && tmp=$(( tmp -1 )) && [[ $tmp -eq 0 ]] && tmp=1 # check tree root exists
srq_name="$(_regex "${root_str}" "\/[^\/]*$")" && srq_name="${srq_name:1}" 
tmp=$(for i in $(cat ${yamlfn_str}|grep "^ *"${srq_name}":"|${BUSYBOX}sed 's/[^ ]//g' | awk '{ print length }'); do echo $(( i % ${tmp} ))|grep 0; done | wc -w)
_tui_log 0 "found path # : ${tmp}"
[[ ${tmp} -eq 0 ]] && _tui_log 4 "root path ${root_str} is not found on ${yamlfn_str} file." && exit 1
# [[ $(expr "${rtime_flt} <= 0" | bc) = 1 || $(echo "${rtime_flt} > 100" | bc) = 1 ]] && _tui_log 4 "rtime should be > 0, < 100" && exit 1 # rtime is in float type 0.0001 ~ 100
mode_arr=(single batch tui tui_web tui_web_respond) # mode option in single / batch / tui / tui_web / tui_web_respond
[[ $(echo "${mode_arr[@]}" | grep -o "${mode_str}" | wc -w) -lt 1 ]] && _tui_log 4 "mode should be in either single, batch, tui, tui_web, tui_web_respond." && exit 1
# todo : disable git clone, wget, curl in yaml file. and lead msg to use offline file
# todo : hash check using jscdn/github https://unix.stackexchange.com/a/234089
# todo: write permission check to tui_log_dir, tui_run_dir, tui_var_net
# [[ -z $(timeout 0.1 nc -n -v -l 2>&1|grep punt) ]] && _tui_log 4 "port binding permission is not available" && exit 1 # port open permission for current user
[[ $dryrun -gt 0 ]] && _tui_log 2 "yaml file ok." && exit 0 # get env and suggest binary

_parse_main_access_log_run() { # parse cmd and run menu. _parse_main_access_log_run "reqid" "data"
    [[ -z "${2}" ]] && return 0
    local addr="" && local pid=0
    echo "CHECK : ${1} ${2:: -7}" # DEBUG
    echo "parse : ${2} ${pids[*]}"
    IFS=$'\n' mapfile -tn 0 d < <(echo "${2:: -7}"| base64 --decode) # parse request yaml
    for((i=0;i<${#d[@]};i++)){
        local tmp="${d[i]}"
        IFS=$'\n' read -d "" -ra arr <<< "${d[i]//\:\ /$'\n'}"
        [[ "${#arr[@]}" != 2 || "${arr[0]}" != "address"  ]] && continue
        addr="${arr[1]}"
    }
    local reqno="" && reqno=$(printf "%05.f" "${1}")
    [[ -z "$addr" ]] && echo -e "E0501\nEOP" > "${tui_net_dir}/REQ${reqno}" && echo -e "E0501\nEOP" > "${tui_net_dir}/RES${reqno}" \
        && return 0 # E0501: no address parsed. record error
    # generate REQ/RES file, run command. generate response file
    [[ ${#addr} -gt 1  ]] && [[ ! -f ${tui_net_dir}/RES${reqno} ]] \
        && echo -e "$addr\nEOP" > "${tui_net_dir}/REQ${reqno}" \
        && ( ${0} --mode single --root ${addr} >${tui_net_dir}/RES${reqno} & ) && pid=$! \
        && pids+=("${pid}") && [[ $( ( _hget "PIDS" "P${pid}"| wc -l ) 2>/dev/null) -eq 0 ]] \
        && _hput "PIDS" "P${pid}" "R${reqno}" && return 0
    # [[ -f ${tui_net_dir}/RES${reqno} ]] && echo -e "E0502\nEOP" > "${tui_net_dir}/REQ${reqno}" && return 0 # E0502: reqid duplicate. record error
    echo -e "E0503\nEOP" > "${tui_net_dir}/REQ${reqno}" && echo -e "E0503\nEOP" > "${tui_net_dir}/RES${reqno}" && return 0 # E0503: unknown error. record error
}

_parse_main_access_log() {
    local t=() && local tmp="" && local reqid="" && local seqid="" && local rqdata=""
    # check running pids for subprocessor and write finish txt to net RES file
    for tpid in "${pids[@]}"; do
        [[ ${tpid//\ } -eq "" ]] && continue
        [[ ! -d "/proc/$tpid/" ]] \
            && pids=("${pids//$tpid}") && tmp=$(_hget "PIDS" "P${tpid}") && tmp=${tmp//R} \
            && echo "pid $tpid reqid: $tmp" \
            && ${BUSYBOX}sed -i "1 i\\\\$tpid:R$tmp> FIN" ${tui_net_dir}/RES${tmp}
    done
    [[ ! -f "${tui_run_dir}/tui.access.log" ]] && echo "cant find log file on "${tui_run_dir}/tui.access.log". please check httpd is running" && exit 1
    IFS=$'\n' mapfile -tn 0 t < <(tail -n +"$(( tui_last_line + 1 ))" "${tui_run_dir}/tui.access.log")
    [[ ${#t[@]} -lt 1 ]] && return 0; # looping every second
    echo -e "-${tui_last_line}-------\n"  # DEBUG
    echo -e "$(tail -n +"$(( tui_last_line + 1 ))" "${tui_run_dir}/tui.access.log")"  # DEBUG
    for((i=0;i<${#t[@]};i++)){
        local tmp=${t[i]}
        # remove if FIN found after finished response sent to client REQ/RES

        local f=$(_regex "${tmp}" ' \/dummy\/tnet\/[a-zA-Z0-9\/+=_]*')
        [[ 1 -gt "${#f}" ]] && echo "${tmp}" >> "${tui_log_dir}/${tui_access_log}" && continue # relay Log non-tui_web requests
        IFS=$'\n' read -d "" -ra arr <<< "${f[0]//\//$'\n'}"
        [[ ${#arr[@]} -lt 6 ]] && continue
        reqid=$(printf "%05.f" ${arr[3]})
        seqid=$(printf "%05.f" ${arr[4]})
        rqdata=${arr[5]}
        local eor=$(_regex "${rqdata}" '__EOR__$')
        [[ $( ( _hget "${reqid}" "${seqid}" |wc -l ) 2>/dev/null) -lt 1 ]] && _hput "${reqid}" "${seqid}" "${rqdata}" # save to hash table https://stackoverflow.com/a/2225712
        # EOR FOUND             # get all data from cache same reqid       # process cmd
        [[ ${#eor[@]} -eq 1 ]] && tmp=$(_hcollect "${reqid}" "${seqid}") && _parse_main_access_log_run "${reqid}" "${tmp}" # && _hinit "${reqid}"
    }
    local tmp=${#t[@]}
    tui_last_line=$(( tmp + tui_last_line ))
}

parse_main() { # https://unix.stackexchange.com/a/548227
    # {{ tui_run_dir }}/tui.access.log -> {{ tui_log_dir }}/{{ tui_access_log }} 
    dbgfile_str="./tui.resoponder.debug.log"
    local tui_last_line=0 # line number cache
    local tui_run_dir="./tui_web/var/run" && local tui_log_dir="./tui_web/var/log" && local tui_access_log="access.log"
    local tui_net_dir="./tui_web/var/net"
    local doc_idt=2 # default single indentation
    IFS=$'\n' read -rd '' -a lines <<<"$yaml_str"
    _main_get_conf # get configurations from yaml from lines

    local pids=()
    for ((;;)); { _parse_main_access_log; sleep 1.1; }
}
[[ $mode_str = "tui_web_respond" ]] && parse_main && exit 0
[[ $mode_str = "single" ]] && single && exit 0
[[ $mode_str != "tui_web_respond" && $mode_str != "single" ]] && main
