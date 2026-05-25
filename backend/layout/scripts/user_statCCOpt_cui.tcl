proc user_statCCOpt {args} {
    set procname [dict get [info frame [info frame]] proc]
    set ARGS(-output) "log"
    parse_proc_arguments -args $args ARGS
    switch $ARGS(-output) {
        "log" {interp alias {} write_cmd {} puts}
        "logv" {interp alias {} write_cmd {} vputs}
        "stdout" {interp alias {} write_cmd {} puts}
        default {error}
    }
    ## listup ccopt cell naming
    redirect -variable show_ccopt_cell_name_info_result {puts [report_cts_cell_name_info]}
    set cell_prefix_list ""
    foreach line [split $show_ccopt_cell_name_info_result "\n"] {
        if {[regexp {Creators:} $line]} {continue}
        if {[lindex $line 0] != ""} {lappend cell_prefix_list "[get_db cts_inst_name_prefix]_[lindex $line 0]"}
    }
    if {[info exists ARGS(-clock_trees)]} {
        set effective_clock_trees ""
        foreach i $ARGS(-clock_trees) {
            if {[get_ccopt_clock_trees $ARGS(-clock_trees)] == ""} {
                puts "WARN($procname): specified clock_tree $ARGS(-clock_tree) not found, ignore"
            } else {
                lappend effective_clock_trees $i
            }
        }
        if {$effective_clock_trees == ""} {
            puts "ERROR($procname): no effective clock_trees found, exit"
            return
        }
       set all_clock_tree_insts [get_db clock_tree:$effective_clock_trees .insts.name ]
       set all_clock_tree_sinks [ get_db clock_tree:$effective_clock_trees .sinks.name ]
    } else {
        set effective_clock_trees "all"
	set all_clock_tree_insts [get_db clock_trees .insts.name]
        set all_clock_tree_sinks [get_db clock_trees .sinks.name]
            }
    set total_num_insts [llength $all_clock_tree_insts]
    set counter 0
    foreach i $all_clock_tree_insts {
        set cell [get_db [get_db inst:$i] .base_cell.name]
        set prefix "OTHER"
        foreach j $cell_prefix_list {
            if {[string match *$j* $i]} {
                set prefix $j
                break
            }
        }
        incr STAT_CCOPT($cell,$prefix)
        incr counter
        puts -nonewline "\r processing  $counter / $total_num_insts"
 flush stdout
    }
    puts ""
    set prop_cell_list ""
    set cell_buf_list ""
       foreach i [get_db cts_buffer_cells] {
         foreach j [get_db base_cells .name $i] {
             lappend cell_buf_list $j
             lappend prop_cell_list $j
        }
     }
    set cell_inv_list ""
         foreach i [get_db cts_inverter_cells] {
         foreach j [get_db base_cells .name $i] {
             lappend cell_inv_list $j
             lappend prop_cell_list $j
         }        
     }
    set cell_oth_list ""
        foreach i [get_db cts_clock_gating_cells] {
         foreach j [get_db base_cells .name $i] {
             lappend cell_oth_list $j
             lappend prop_cell_list $j
         }
     }
    set prop_cell_ulist [lsort -unique $prop_cell_list]
    set prefix_list ""
    set value_list ""
    foreach i [array names STAT_CCOPT] {
        if {[regexp {(\S+)\,(\S+)} $i matchVar cell prefix]} { 
             if {[get_db [get_db base_cell:$cell  ] .is_buffer]} {
                 lappend cell_buf_list $cell
             } elseif {[get_db [get_db base_cell:$cell ] .is_inverter]} {
                 lappend cell_inv_list $cell
             } else {
                 lappend cell_oth_list $cell
             }
            lappend prefix_list $prefix
            lappend value_list $STAT_CCOPT($i)
        } else {
            error "unexpected array prefix_listnames $i"
        }
    }
    set cell_buf_ulist [lsort -unique $cell_buf_list]
    set cell_inv_ulist [lsort -unique $cell_inv_list]
    set cell_oth_ulist [lsort -unique $cell_oth_list]
    set prefix_ulist   [lsort -unique $prefix_list]
    write_cmd "### \[\[ clock_tree(s) tree stats : $effective_clock_trees (# of sinks = [llength $all_clock_tree_sinks]) \]\] ###"
    set max_cell_string_length 0
    foreach i [concat $cell_buf_ulist $cell_inv_ulist $cell_oth_ulist "TOTAL"] {
        if {[string length $i] > $max_cell_string_length} {
            set max_cell_string_length [string length $i]
        }
    }
    set max_result_string_length 0
    foreach i [concat $prefix_ulist $value_list "TOTAL"] {
        if {[string length $i] > $max_result_string_length} {
            set max_result_string_length [string length $i]
        }
    }
    set lenc [expr $max_cell_string_length + 2]
    set lenr [expr $max_result_string_length + 1]
    ## prepare real final_col_key / row_key
    if {[info exists ARGS(-keep_empty)]} {
        set row_keys [concat $cell_buf_ulist $cell_inv_ulist $cell_oth_ulist]
    } else {
        set row_keys ""
        foreach i [concat $cell_buf_ulist $cell_inv_ulist $cell_oth_ulist] {
            foreach j [array names STAT_CCOPT $i,*] {
                if {$STAT_CCOPT($j) > 0} {
                    lappend row_keys $i
                    break
                }
            }
        }
    }
    set col_keys $prefix_ulist
    ## write
    # fisrt row
    write_cmd -nonewline "|[format "%${lenc}s" ""]"
    set avoid_dup ""
    foreach i $col_keys {
        if {[lsearch $avoid_dup $i] > -1} {continue}
        write_cmd -nonewline "|[format "%${lenr}s"  $i]"
        lappend avoid_dup $i
    }
    write_cmd "|[format "%${lenr}s" "TOTAL"]|"
    # second row
    write_cmd -nonewline "+[string repeat "-" ${lenc}]"
    set avoid_dup ""
    foreach i $col_keys {
        if {[lsearch $avoid_dup $i] > -1} {continue}
        write_cmd -nonewline "+[string repeat "-" ${lenr}]"
        lappend avoid_dup $i
    }
    write_cmd "+[string repeat "-" ${lenr}]+"
    # middle row
    set avoid_dup ""
    foreach i $row_keys {
        if {[lsearch $avoid_dup $i] > -1} {continue}
        if {[lsearch $prop_cell_ulist $i] > -1} {
            write_cmd -nonewline "|[format "%${lenc}s" "@:$i"]"
        } else {
            write_cmd -nonewline "|[format "%${lenc}s" $i]"
        }
        set row_total 0
        foreach j $col_keys {
            if {[info exists STAT_CCOPT($i,$j)]} {
                write_cmd -nonewline "|[format "%${lenr}s" $STAT_CCOPT($i,$j)]"
                incr row_total $STAT_CCOPT($i,$j)
            } else {
                write_cmd -nonewline "|[format "%${lenr}s" "0"]"
            }
        }
        write_cmd "|[format "%${lenr}s" $row_total]|"
        lappend avoid_dup $i
    }
    # before last row
    write_cmd -nonewline "+[string repeat "-" ${lenc}]"
    set avoid_dup ""
    foreach i $col_keys {
        if {[lsearch $avoid_dup $i] > -1} {continue}
        write_cmd -nonewline "+[string repeat "-" ${lenr}]"
        lappend avoid_dup $i
    }
    write_cmd "+[string repeat "-" ${lenr}]+"
    # last row
    write_cmd -nonewline "|[format "%${lenc}s" "TOTAL"]"
    set avoid_dup ""
    set total_total 0
    foreach i $col_keys {
        if {[lsearch $avoid_dup $i] > -1} {continue}
        set col_total 0
        foreach j [array names STAT_CCOPT *,$i] {
            incr col_total $STAT_CCOPT($j)
        }
        write_cmd -nonewline "|[format "%${lenr}s" $col_total]"
        lappend avoid_dup $i
        incr total_total $col_total
    }
    write_cmd "|[format "%${lenr}s" $total_total]|"
}

# logCommand user_statCCOpt
define_proc_arguments user_statCCOpt  \
-info "report overview of CCOpt cell name code usage"  \
-define_args { {-clock_trees "specify clock_trees to report cell name code usage
 if not specified, all clock_tree are checked" "" string optional}
        {-keep_empty "display empty col/row
 default=empty col/row is not printed" "" boolean optional}
        {-output "output command
 default=log" "" one_of_string {optional value_help {values "log logv stdout"}}}
    }

