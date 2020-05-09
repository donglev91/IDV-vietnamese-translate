#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

set java [exec which java]



proc readFile {file} {
    set fp [open $file r]
    set contents [read $fp]
    close $fp
    return $contents
}

proc writeFile {file content} {
    set fp [open $file w]
    puts $fp $content
    close $fp
}

proc writeLeft {c} {
    append ::leftHtml "$c\n"
}

proc writeRight {c} {
    append ::rightHtml "$c\n"
}



proc processBundle {archiveName bundle archiveDir resultsDir} {
    global java
    set logFile   [file join $resultsDir $archiveName.log]

    set doJar [file exists idv.jar]

    set testpause 120

    write "<hr><h2><a name=${archiveName}>$archiveName</a></h2>\n";
    if {$doJar} {
        write "$java -Xmx512m -jar idv.jar  -nodefault   -test $archiveName $resultsDir  $bundle<br>"
    }  else {
        write "$java -Xmx512m ucar.unidata.idv.DefaultIdv  -nodefault  -test $archiveName $resultsDir  $bundle<br>"
    }
    write "at [clock format [clock seconds]]<p>"
    ##If it is a jnlp file put a link to it.
    if {[regexp {.*\.jnlp$} $bundle]} {
        write "<a href=$bundle>$bundle</a><p>"

    }

    set descFile   [file join $archiveDir "$archiveName.txt"]
    if {[file exists $descFile]} {
        write "<b>Description:</b><br>"
        write  [readFile $descFile]
        write "<p>"
    } 


    set inError 0

    lappend ::archives $archiveName
    if {$::doJava} {
        if {$doJar} {
            if {[catch {exec $java -Xmx512m  -jar idv.jar  -nodefault   -test $archiveName   $resultsDir  $bundle 2> $logFile } err]} {
                lappend ::errors [list $archiveName $err]
                write "<div><font  color=red>An error has occurred:</font></div> $err<p>" 
                set inError 1
            }
        } else {
            if {[catch {exec $java -Xmx512m  ucar.unidata.idv.DefaultIdv -nodefault    -test $archiveName   $resultsDir  $bundle 2> $logFile } err]} {
                lappend ::errors [list $archiveName $err]
                write "<div><font  color=red>An error has occurred:</font></div> $err<p>" 
                set inError 1
            }
        }
    }
    set logContents [readFile $logFile]
    set contents ""
    set imageFiles [list]
    set didone 0
    foreach line [split $logContents "\n" ] {
        if {[regexp {^Warning:\s*Cannot\s* convert} $line match file]} {
            ##Skip this
        } elseif {[regexp {^Writing\s*image:(.*)$} $line match file]} {
            lappend imageFiles $file
        } else {
            append contents "$line\n"
        }
    }



    if {[string trim $contents] != ""} {
        write "<b>Output:</b> <div style=\"background-color:red;\"><pre>[string trim $contents]</pre></div>"
    }
    
    if {$inError} {
        return;
    }


    set testDir   [pwd]

    foreach origImage [glob -nocomplain [file join $archiveDir $archiveName*.jpg]] {
        set originalImages([file tail $origImage])  $origImage
    }


    foreach image $imageFiles {
        set testImage [file join $testDir $image]
        set originalImage [file join $archiveDir [file tail $image]]
        catch {unset originalImages([file tail $originalImage])}
        writeImage $archiveName $originalImage $testImage
    }


    foreach image [array names originalImages] {
        writeImage $archiveName $originalImages($image) ""
    }

}

proc imageTag {image} {

#    if {[file exists $image]} {
        return "<a href=$image><img border=0 width=100% src=$image></a>"
#    } 
#    return "<b>Missing</b>"
}


proc writeImage {archiveName originalImage testImage} {
    set tail [file tail $originalImage]
    write "<a name=$tail>"
    write "<center><b>[file tail $testImage]</b></center><table width=100%><tr><td>Original</td><td>Test image</td></tr>"
    set img1 [imageTag  $originalImage]
    set img2 ""
    if {[file exists $originalImage] && [file exists $testImage]} {
        set diffFP [open  "|diff $originalImage $testImage"]
        set diff [string trim [read $diffFP]]
        catch {close $diffFP}
        if {$diff != ""} {
            lappend ::imageErrors(DIFF) "<a href=resultsRight.html#$tail target=display>[file tail $originalImage]</a>"
        }
        set img2 [imageTag $testImage]
    } elseif {[file exists $originalImage]} {
        lappend ::imageErrors(MISSINGTEST) "<a href=resultsRight.html#[file tail $originalImage] target=display>[file tail $originalImage]</a>"
        set img2 "Missing: $testImage"
    } else {
        lappend ::imageErrors(MISSINGORIGINAL) "<a href=resultsRight.html#$tail target=display>[file tail $originalImage]</a>"
        set img2 [imageTag $testImage]
    }
    write "<tr valign=top><td width=50%>$img1</td><td width=50%>$img2</table><p>"
}


proc write {s} {
    append  ::html "$s\n"
}


proc getImageErrors {diff missingtest missingoriginal} {
    set html ""
    if {[llength $diff]} {
        foreach error $diff {
            append html "$error<br>"
        }
    }

    if {[llength $missingtest]} {
        foreach error $missingtest {
            append html "$error<br>"
        }
    }


    if {[llength $missingoriginal]} {
        foreach error $missingtest {
            append html "$missingoriginal<br>"
        }
    }



    return $html
}

proc getErrors {errors} {
    set html ""
    if {[llength $errors]} {
        append html "<hr><b>There were errors:</b><p>"
        foreach error $errors {
            foreach {archive msg} $error break;
            append html "<a href=resultsRight.html#${archive} target=display>$archive<br></a>$msg<p>" 
        }
    }
    return $html
}




set ::moveResults 0

set tmpArchives [list]
foreach arg $argv {
    switch -- $arg {
        -moveresults {
            set ::moveResults 1
        }
        default {
            lappend tmpArchives $arg
        }
    }
}



if {[llength $tmpArchives]  == 0} {
    set tmpArchives [concat [glob -nocomplain  /upc/share/metapps/test/archives/*]]
}




set archiveDirs [list]
foreach archiveDir $tmpArchives {
    if {[regexp {_results$} $archiveDir]} {continue;}
    if {[regexp {_bak$} $archiveDir]} {continue;}
    if {![regexp {^/} $archiveDir]} {
        set archiveDir "/upc/share/metapps/test/archives/$archiveDir"
    }
    if {![file isdirectory $archiveDir]} {continue;}
    lappend archiveDirs $archiveDir
}



if {$::moveResults} {
    puts "Moving results"
    foreach archiveDir $archiveDirs {
        set resultsDir ${archiveDir}_results
        if {![file exists $resultsDir]} {
            continue
        }
        set archiveName [file tail [file root $archiveDir]]
        puts "\tArchive: $archiveName $resultsDir to $archiveDir"
        set backup ${archiveDir}_bak
        if {[file exists $backup]} {
            file delete -force $backup
        }
        file rename -force $archiveDir $backup
        file rename -force $resultsDir $archiveDir 
        set jnlp [file join ${archiveDir}_bak $archiveName.jnlp]
        if {[file exists $jnlp]} {
            file rename -force $jnlp $archiveDir
        }
    }
    exit
}



set ::rightHtml ""
set ::leftHtml ""
set ::doJava 1
set ::allHtml ""
set ::allErrors [list]
set ::archives [list]

foreach archiveDir $archiveDirs {
    set ::html ""
    set errors [list]
    set ::imageErrors(DIFF) [list]
    set ::imageErrors(MISSINGTEST) [list]
    set ::imageErrors(MISSINGORIGINAL) [list]

    set archiveName [file tail $archiveDir]
    set bundleFile [file join $archiveDir $archiveName.jnlp]
    if {![file exists $bundleFile]} {
        puts "No bundle: $bundleFile"
        continue;
    }
    set resultsDir [file join [file dirname $archiveDir] "${archiveName}_results"]
    if {$::doJava} {
        file delete -force $resultsDir
        file mkdir $resultsDir
    }
    file copy -force $bundleFile $resultsDir



    processBundle $archiveName $bundleFile $archiveDir $resultsDir

    set color ""
    if {![llength $::imageErrors(DIFF)] && 
        ![llength $::imageErrors(MISSINGTEST)] && 
        ![llength $::imageErrors(MISSINGORIGINAL)]} {
        set color green
    } else {
        set color red
    }
    writeLeft "<li> <b><span style=\"background-color:$color\"><a href=resultsRight.html#${archiveName} target=display>$archiveName</a></span></b> <div style=\"margin-left:10\">"
    writeLeft  [getErrors $errors]
    writeLeft  [getImageErrors $::imageErrors(DIFF) $::imageErrors(MISSINGTEST) $::imageErrors(MISSINGORIGINAL)]
    writeLeft "</div>"
    writeLeft "<hr>"


    set allErrors [concat $::allErrors $errors]


    append allHtml $::html
    set fp [open [file join $resultsDir results.html] w]
    puts $fp [getErrors $errors]
    puts $fp [getImageErrors $imageErrors(DIFF) $imageErrors(MISSINGTEST) $imageErrors(MISSINGORIGINAL)]
    puts $fp $::html
    close $fp
}




writeRight "<p>"
writeRight $allHtml



set frame {<frameset cols="200,*" > 
  <frame name=left src="resultsLeft.html">
  <frame name=display   src="resultsRight.html">
</frameset>}

writeFile "resultsLeft.html" $::leftHtml
writeFile "resultsRight.html" $::rightHtml
writeFile results.html $frame

