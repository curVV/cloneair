
namespace import ::tcl::mathfunc::sin ::tcl::mathfunc::cos ::tcl::mathfunc::atan2 ::tcl::mathfunc::sqrt


proc Pi {} {return 3.1415926535897931}

proc degrees_to_rads {degrees} {
    return [expr $degrees * [expr [Pi] / 180]]
}

proc haversine {lata lona latb lonb} {
    #Haversine Formula
    #
    #a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
    #c = 2 ⋅ atan2( √a, √(1−a) )
    #d = R ⋅ c 
    #    where   φ is latitude, λ is longitude, R is earth's radius (mean radius = 6371km);
    #    angles need to be in radians to pass to trig functions.
    #
    #The haversine formula 'remains particularly well-conditioned for numerical computa­tion 
    #even at small distances' - unlike calcula­tions based on the spherical law of cosines. 
    #The '(re)versed sine' is 1−cosθ, and the 'half-versed-sine' is (1−cosθ)/2 or sin²(θ/2) 
    #as used above.
    #
    #Once widely used by navigators, it was described by Roger Sinnott in Sky & Telescope 
    #magazine in 1984 ("Virtues of the Haversine"): Sinnott explained that the angular 
    #separa­tion between Mizar and Alcor in Ursa Major - 0°11'49.69" - could be accurately 
    #calculated on a TRS-80 using the haversine.
    #
    #For the curious, c is the angular distance in radians, and a is the square of half the 
    #chord length between the points.
    #
    #If atan2 is not available, c could be calculated from 2 ⋅ asin( min(1, √a) ) 
    #(including protec­tion against rounding errors).
    
    set ER 6371000.0

    set lat1 [degrees_to_rads $lata]
    set lat2 [degrees_to_rads $latb]
    set lon1 [degrees_to_rads $lona]
    set lon2 [degrees_to_rads $lonb]

    set distLat [expr $lat2 - $lat1]
    set distLon [expr $lon2 - $lon1]
    
    set a [expr [sin [expr $distLat / 2]] * [sin [expr $distLat / 2]] + [sin [expr $distLon / 2]] * [sin [expr $distLon / 2]] * [cos $lat1] * [cos $lat2]]
    
    set c [expr 2 * [ atan2 [sqrt $a] [sqrt [expr 1 - $a]]]]
    
    set d [expr $ER * $c]
    
    return [expr $d * 3.280839895013]
}
