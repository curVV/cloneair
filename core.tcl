
source scripts/cloneair/geo.tcl
source scripts/cloneair/ywx.tcl

proc wx {arg} {
    set webstring "http://www.google.com/ig/api?weather=[lrange $arg 0 end]"
    if {[catch {set wetterdata [exec wget --quiet -O - $webstring]} err]} {
        return "Google Weather not available."
    }
    set i [regexp {(?i)<city data=\"(.*?)\"/>} $wetterdata -> wetter(stadt)]
    if {$i == 0} { return "Google Weather not available for $arg." }
    regexp {(?i)<postal_code data=\"(.*?)\"/>} $wetterdata -> wetter(plz)
    regexp {(?i)temp_c data=\"(.*?)\"/>} $wetterdata -> wetter(current_celsius)
    regexp {(?i)humidity data=\"(.*?)\"/>} $wetterdata -> wetter(current_feuchtigkeit)
    regexp {(?i)wind_condition data=\"(.*?)\"/>} $wetterdata -> wetter(current_wind)
    regexp {(?i)condition data=\"(.*?)\"/>} $wetterdata -> wetter(current_weather)
    if {[string length $wetter(current_weather)] == 0} { set wetter(current_weather) "Cloud condition not available" }
    return "Weather for $wetter(stadt) - Temp: $wetter(current_celsius)°C - $wetter(current_wind) - $wetter(current_feuchtigkeit) - $wetter(current_weather)"
}

proc msg_wx {nick host hand arg} {
    putquick "notice $nick :[wx $arg]"
}

proc pub_wx {nick host hand chan arg} {
    putquick "notice $nick :[wx $arg]"
}

proc help {chan} {
    putquick "notice $chan :wxbot the friendly FlightGear bot"
    putquick "notice $chan :These commands will work in the public channel or via private /msg"
    putquick "notice $chan :!help        Show list of commands"
    putquick "notice $chan :!wx city     Display Google Weather for city"
    putquick "notice $chan :!taf   icao  Display TAF for airport (ICAO code)"
    putquick "notice $chan :!metar icao  Display METAR for airport (ICAO code)"
    putquick "notice $chan :!aptinfo string List airports matching string (>4 characters), or"
    putquick "notice $chan :!aptinfo icao   Display airport info (ICAO code)"
    putquick "notice $chan :!mp         List pilots on FlightGear multiplayer servers"
    putquick "notice $chan :!dist icao icao        Calculate distance between airports"
}

proc msg_help {nick host hand arg} {
    help $nick
}

proc pub_help {nick host hand chan arg} {
    help $nick
}

proc metar {icao} {
    set webstring "https://www.aviationweather.gov/metar/data?ids=$icao"
    set reply ""
    if {[catch {append reply [exec wget --quiet -O - $webstring | sed -n -e {/Data starts/,/Data ends/p} | sed -e {s/<[^>]*>//g} ]} err]} {
        set reply "METAR not available."
    }
    return $reply
}

proc cmd_metar {nick host hand d {e 0}} {
    global lastbind

    if {$e == 0} {
        set arg $d
    } else {
        set chan $d
        set arg $e
    }

    set icao [string toupper $arg]
    set reply [metar $icao]
    foreach i [split $reply "\n"] {
        if {$e == 0 || [string index $lastbind 0] == "!"} {
            putquick "notice $nick :$i"
        } else {
            putquick "privmsg $chan :$i"            
        }
    }
    return 1
}

proc cmd_distance {nick host hand d {e 0}} {
    global lastbind

    if {$e == 0} {
        set arg $d
    } else {
        set chan $d
        set arg $e
    }
    set icaos [split $arg " "]
    if {[llength $icaos] == 2} {
        set icao_a [string toupper [lindex $icaos 0]]
        set icao_b [string toupper [lindex $icaos 1]]
        set distance [distance $icao_a $icao_b]
        set reply "${icao_a}->${icao_b}: $distance"
        if {$e == 0 || [string index $lastbind 0] == "!"} {
            putquick "notice $nick :$reply"
        } else {
            putquick "privmsg $chan :$reply"
        }
    }
    return 1
}

proc taf {icao} {
    set webstring "https://www.aviationweather.gov/taf/data?ids=$icao"
    set reply {}
    if {[catch {append reply [exec wget --quiet -O - $webstring | sed -n -e {/Data starts/,/Data ends/p} | sed -e {s/<[^>]*>//g} -e {s/&nbsp;/ /g} ]} err]} {
        set reply "TAF not available."
    }
    return $reply
}

proc msg_taf {nick host hand arg} {
    set icao [string toupper $arg]
    set reply [taf $icao]
    foreach i [split $reply "\n"] {
        putquick "notice $nick :$i"
    }
}

proc pub_taf {nick host hand chan arg} {
    set icao [string toupper $arg]
    set reply [taf $icao]
    foreach i [split $reply "\n"] {
        putquick "notice $nick :$i"
    }
}

proc rwyinfo {icao} {
    global fgdata
    set reply {}
    set rwytext {}

    if {[catch {set text [exec zcat $fgdata/Airports/apt.dat.gz | sed -E -n "/^1 .+ $icao /,/^\r/p"]} err]} {return "No runway info."}

    #regexp {^1\s+(\d+)\s+\d+\s+\d+\s+(\w+)\s+(.+)} $text -> elev icao name
    foreach i [split $text "\n"] {
        set rwy_info [regexp -all -inline -- {\S+} $i]

        if {[lindex $rwy_info 0] == "100"} {
            set rwy_width  [lindex $rwy_info 1]
            set rwy_a_name [lindex $rwy_info 8]
            set rwy_a_lat [lindex $rwy_info 9]
            set rwy_a_lon [lindex $rwy_info 10]
            set rwy_b_name [lindex $rwy_info 17]
            set rwy_b_lat [lindex $rwy_info 18]
            set rwy_b_lon [lindex $rwy_info 19]
            set rwy_len [format "%.2f" [haversine $rwy_a_lat $rwy_a_lon $rwy_b_lat $rwy_b_lon]]
            append rwytext "[string toupper $rwy_a_name]/[string toupper $rwy_b_name] (w:$rwy_width' l:$rwy_len')  "
        }
    }
    append reply "  Runways $rwytext\n"

    return $reply
}

proc ilsinfo {icao} {
    global fgdata
    set reply {}

    # 4 -37.66076700  144.82202100    433 10930  18     274.130 IMW  YMML 27  ILS-cat-
    if {[catch {set text [exec zgrep -i " $icao " $fgdata/Navaids/nav.dat.gz]} err]} {return "  No ILS.\n"}

    foreach i [split $text "\n"] {
        regexp {^(\d+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(.+)} $i -> type freq id name
        if {$type == 4} {
            regsub "[string toupper $icao]" $name RW name
            regexp {^(\d\d\d)(\d\d)} $freq -> d1 d2
            append reply "  $name ($d1.$d2 $id)\n"
        }
    }
    return $reply
}

proc navinfo {lat lon} {
    global fgdata
    set reply {}
    regexp {(-?\d+)} $lat -> lat
    regexp {(-?\d+)} $lon -> lon

    #if {[catch {set text [exec zgrep '^[23]\s$lat\S+\s$lon' $fgdata/Navaids/nav.dat.gz]} err]} {return "No data."}
    if {[catch {set text [exec zgrep -E "^\[23\] +$lat.+ +$lon" $fgdata/Navaids/nav.dat.gz]} err]} {return "No data."}

    foreach i [split $text "\n"] {
        regexp {^(\d+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(.+)} $i -> type freq id name
        if {$type == 3} { regexp {^(\d\d\d)(\d\d)} $freq -> d1 d2; set freq "$d1.$d2" }
        append reply "$name ($freq $id)   "
    }
    return "  Navaids $reply\n"
}


proc distance {icao_a icao_b} {

    global fgdata

    if {[catch {set icao_a_text [exec zgrep -P -A 1 -i "^1\\s+.*\\s+${icao_a}\\s+" $fgdata/Airports/apt.dat.gz]} err]} {return "Not found: $icao_a"}
    if {[catch {set icao_b_text [exec zgrep -P -A 1 -i "^1\\s+.*\\s+${icao_b}\\s+" $fgdata/Airports/apt.dat.gz]} err]} {return "Not found: $icao_b"}

    set icao_a_runway_data [regexp -all -inline -- {\S+} [lindex [split $icao_a_text "\n"] 1]]
    set icao_b_runway_data [regexp -all -inline -- {\S+} [lindex [split $icao_b_text "\n"] 1]]

    if {[lindex $icao_a_runway_data 0] == "100"} {
        set icao_a_lat [lindex $icao_a_runway_data 9]
        set icao_a_lon [lindex $icao_a_runway_data 10]
    } else {
        return "Not found: $icao_a"
    }

    if {[lindex $icao_b_runway_data 0] == "100"} {
        set icao_b_lat [lindex $icao_b_runway_data 9]
        set icao_b_lon [lindex $icao_b_runway_data 10]
    } else {
        return "Not found: $icao_b"
    }
    
    # as nautical miles
    set distance [format "%.2f" [expr [haversine $icao_a_lat $icao_a_lon $icao_b_lat $icao_b_lon] * 0.0001645788336933]]

    return "$distance NM"
}


proc aptinfo {arg} {
    # ICAO, name, elev, rwy, ILS
    global fgdata
    global max_results
    set count 0
    set reply {}
    set rwytext {}

    # find exact match if len(arg) < 5
    if {[string length $arg] < 5} {set str " $arg "
    } else {set str $arg}

    # 1     433 1 1 YMML Melbourne Intl
    if {[catch {set text [exec zgrep -A 1 -i "^1 .*$str" $fgdata/Airports/apt.dat.gz]} err]} {return "No match."}


    foreach i [split $text "\n"] {
        regexp {^1\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(.+)} $i -> elev icao name

        if {$count > $max_results} {
            append reply "...max limit reached ($max_results)\n"
            break            
        }

        if {[regexp {^100\s+([0-9\-.LRCX]+\s+){8}(-?)([0-9\.]+)\s+(-?)([0-9\.]+)\s} $i -> nn lah lat loh lon] == 1} {
            if {$lah == "-"} {set las S} else {set las N}
            if {$loh == "-"} {set los W} else {set los E}
            append reply "$icao $name (elev $elev)   $las$lat $los$lon\n"
            incr count
        }
    }

    if {$count == 1} {
    #  # dump rwy and ILS info too, if only 1 apt matched
        append reply [rwyinfo $icao]
        append reply [ilsinfo $icao]
        append reply [navinfo $lah$lat $loh$lon]
    }

    if {$count == 0} {
        set reply "No match. (2)"
    }

    return $reply
}

proc cmd_aptinfo {nick host hand d {e 0}} {
    global lastbind

    if {$e == 0} {
        set arg $d
    } else {
        set chan $d
        set arg $e
    }
    foreach i [split [aptinfo $arg] "\n"] {
        if {$e == 0 || [string index $lastbind 0] == "!"} {
            putquick "notice $nick :$i"
        } else {
            putquick "privmsg $chan :$i"
        }
    }
}

proc mp {} {
    set reply {}
    set count 0

    set text [exec nc mpserver15.flightgear.org 5001 | grep @] 
    foreach i [split $text "\n"] {
        regexp {^([^@]+)} $i -> n
        append reply "$n "
        incr count
    }
    return "$count Multiplayer pilots: $reply"
}

proc msg_mp {nick host hand arg} {
    putquick "notice $nick :[mp]"
}

proc pub_mp {nick host hand chan arg} {
    putquick "notice $nick :[mp]"
}

proc alt {qnh} {
    return "$qnh hPa = [string range [expr $qnh * 0.02953] 0 5] inHg"
}

proc msg_alt {nick host hand arg} {
    putquick "notice $nick :[alt $arg]"
}

proc pub_alt {nick host hand chan arg} {
    putquick "notice $nick :[alt $arg]"
}
