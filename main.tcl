# adapted from metarbot 0.7 by reeed


####  SETTINGS  ####

# specify path to $FG_ROOT
set fgdata "/usr/share/flightgear"

# set maximum number of search results
set max_results 20


#### COMMAND BINDINGS ####

bind pub - !help pub_help
bind msg - !help msg_help
bind msg -  help msg_help

bind pub - !wx pub_wx
bind msg - !wx msg_wx
bind msg -  wx msg_wx

bind pub - .metar cmd_metar
bind pub - !metar cmd_metar
bind msg - !metar cmd_metar
bind msg -  metar cmd_metar

bind pub - .dist cmd_distance
bind pub - !dist cmd_distance
bind msg - !dist cmd_distance
bind msg - dist cmd_distance

bind pub - !taf pub_taf
bind msg - !taf msg_taf
bind msg -  taf msg_taf

bind pub - .aptinfo cmd_aptinfo
bind pub - !aptinfo cmd_aptinfo
bind msg - !aptinfo cmd_aptinfo
bind msg -  aptinfo cmd_aptinfo

bind pub - !mp pub_mp
bind msg - !mp msg_mp
bind msg -  mp msg_mp
#bind pub - !ywx pub_yahoowx
#bind msg - !ywx msg_yahoowx
#bind msg -  ywx msg_yahoowx
bind pub - !wu pub_wu
bind msg - !wu msg_wu
bind msg -  wu msg_wu
bind pub - !alt pub_alt
bind msg - !alt msg_alt
bind msg -  alt msg_alt

source scripts/cloneair/core.tcl

putlog "cloneair scripts 0.0.1 loaded"
putlog "adapted from metarbot 0.7 by reeed"
