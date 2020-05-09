<?xml version="1.0" encoding="ISO-8859-1"?>
<isl
   loop="1"
   offscreen="false"
   debug="true">

<!-- 
This file shows how to generate google earth, quicktime, etc., products
using the isl. This also automatically generates an html page
(named from the target attribute in the generate_start call below)
and scp's  all of the files to a web site or cp's them somewhere

This file can be evaluated with:
idv bundles.isl

You can make your own version of this. You need to 
change the target, wwwroot and scpdest in the generate_start tag below
The wwwroot points to where the generated files reside.
The scpdest is used to scp the files to the web server (optional)
The cpdest is used to cp the files somewhere  (optional)


You need to do the following import to include the generate library
Then call generate_start, passing in the relevant arguments.
Then do successive generate calls
Then finish with  the generate_end call
 -->

<!-- Import the library -->
  <import file="/ucar/unidata/idv/isl/generate.isl"/>


<!--
The generate_ flags allow you to control what is generated.
You can also include them in the generate calls to
override the default (e.g., don't generate a quicktime movie
for a particular bundle)

The filepath flag is where the products are first written out to

The "ignore_" part of ignore_scpdest comments out that attribute
If it was there we would try to scp the generated products to that
destination.
-->

  <generate_start 
        title="Example IDV Image Products"
        description="Some example image products generated by the IDV"
        target="examples"
        wwwroot="http://www.unidata.ucar.edu/software/idv/examples"
        ignore_cpdest="/some/path"
        ignore_scpdest="somemachine:/somepath"
        filepath="${islpath}"
        generate_html="1"
        generate_kmz="1"
        generate_mov="1"
        generate_animatedgif="1"
        generate_image="1"/>


<!-- 
Put any number of generate calls here. There should be a ${id}.jnlp file
in this directory.  You can make the .jnlp files from the idv by
doing a File-Save As and specifying a jnlp file. When asked you
should include the bundle in the jnlp file.


id  is used to uniquely identify the products

bundle is the bundle to load. Note: the {islpath} makes this relative to
where this isl file is

The transparency attribute can be "none" but is normally the background color
of the idv view that is being captured. We make this color transparent.

-->


  <generate
     id="example1"
     bundle="${islpath}/example1.jnlp"
     label="This is example 1"
     generate_kmz="1"
     generate_mov="1"
     generate_animatedgif="1">
  </generate>


  <generate
     id="example2"
     bundle="${islpath}/example2.jnlp"
     label="This is example 2"
     generate_kmz="1"
     generate_mov="1"
     generate_animatedgif="1">
  </generate>



  <generate_end/>

</isl>