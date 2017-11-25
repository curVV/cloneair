proc wu_query {place} {
  set query "http://api.wunderground.com/auto/wui/geo/GeoLookupXML/index.xml?query=$place"

  if {[catch {set text [exec wget -q -O - $query]} err]} {
    return "Error: $err"
  }

  regexp {woeid>([^<]+)<} $text -> woeid
}

proc wu {icao} {
  set query "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=$icao"

  if {[catch {set text [exec wget -q -O - $query]} err]} {
    return "Error: $err"
  }

  regexp {full>([^<]+)} $text -> name
  regexp {country_iso3166>([^<]+)} $text -> country
  regexp {weather>([^<]+)} $text -> weather
  regexp {temperature_string>([^<]+)} $text -> temp
  regexp {relative_humidity>([^<]+)} $text -> humid
  regexp {wind_string>([^<]+)} $text -> wind
  regexp {forecast_url>([^<]+)} $text -> url

  return "wunderground.com conditions for $name, $country: Temp $temp, Wind $wind, humidity $humid, $weather\n$url"
}

proc msg_wu {nick host hand arg} {
  foreach i [split [wu $arg] "\n"] {
    putquick "notice $nick :$i"
  }
}

proc pub_wu {nick host hand chan arg} {
  foreach i [split [wu $arg] "\n"] {
    putquick "notice $nick :$i"
  }
}

#########################################

# WU forecast
proc wf {place} {
  set query "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=$place"

  if {[catch {set text [exec wget -q -O - $query]} err]} {
    return "Error: $err"
  }

  regexp {full>([^<]+)} $text -> name
  regexp {country_iso3166>([^<]+)} $text -> country
  regexp {weather>([^<]+)} $text -> weather
  regexp {temperature_string>([^<]+)} $text -> temp
  regexp {relative_humidity>([^<]+)} $text -> humid
  regexp {wind_string>([^<]+)} $text -> wind
}
#########################################

proc yahoowx {place} {
  set query "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20geo.places%20where%20text=%22$place%22"

  if {[catch {set text [exec wget -q -O - $query]} err]} {
    return "Error: $err"
  }

  regexp {woeid>([^<]+)<} $text -> woeid
  regexp {name>([^<]+)<} $text -> name
  regexp {country[^>]+>([^<]+)<} $text -> country
  regexp {latitude>([^<]+)<} $text -> latitude
  regexp {longitude>([^<]+)<} $text -> longitude

  set query "http://weather.yahooapis.com/forecastrss?w=$woeid&u=c"

  if {[catch {set text [exec wget -q -O - $query | grep -e yweather -e "not found"]} err]} {
    return "Error: $err"
  }

  if {[string first "not found" $text] > -1} {
    return "Location not found."
  }

  regexp {temperature="(.)} $text -> deg
  regexp {distance="([^"]+)} $text -> dist
  regexp {direction="([^"]+)} $text -> dir
  if {[string first ":wind" $text] > -1} {
    regexp {speed="([^"]+)} $text -> spd
  }
  regexp {humidity="([^"]+)} $text -> humid
  regexp {temp="([^"]+)} $text -> temp
  regexp {sunrise="([^"]+)} $text -> sunrise
  regexp {sunset="([^"]+)} $text -> sunset
  regexp {text="([^"]+)} $text -> wxtext

  return "Current weather for $name, $country: $wxtext, $temp°$deg, humidity $humid%, wind $spd from $dir. Sunrise $sunrise, sunset $sunset"
}

proc msg_yahoowx {nick host hand arg} {
  putquick "notice $nick :[yahoowx $arg]"
}

proc pub_yahoowx {nick host hand chan arg} {
  putquick "notice $chan :[yahoowx $arg]"
}
