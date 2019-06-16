# bin2unit
A small utility to convert binary files to a format suitable for using it with Free Pascal

bin2unit - bin to pascal converter
----------------------------------

(c) 2008-2010 - Francesco Lombardi

Released under the terms of the MIT  License (more info on LICENSE file)

## Description

A small utility to convert binary files to a format suitable for using it with
Free Pascal.  I made it mainly for converting graphic and  audio files for gba 
and nds, but it can be used for other platforms too, I suppose =P
bin2unit works in two modes:
  
    * unit mode = it creates  a single .pp file, that contains  big const arrays
                  where it is stored  the  binary's datas converted  from passed
                  files. 
  
    * asm mode  = it creates .s files, that contain the binary's datas converted
                  from passed files, and a  .pp unit, that  includes the  object 
                  files (.o) (that come from the .s ones, by  assembling it) and 
                  declares the  variables needed  to access the  datas stored in 
                  these  object  files.  ASM mode  is  useful  when you  want to 
                  relocate datas into a specific region of the executable. 



## Usage

    Usage: bin2unit [-<options>] [binfile]

    Example: bin2unit -Stext -A2 -Nmyvar image1.bmp image2.pcx 

    Options:
     -U          Creates a pascal unit from the binary file. -S and -A are ignored
     -S<string>  Relocates data in a specified section (default=rodata)
     -A<integer> Sets alignment value (default=4)
     -N<string>  Sets variable base name (default=first binfile)
     -O<string>  Sets output path (default=first binfile)
     -V          Shows version info
     -? or -H    Shows help



## Hints'n'tips

First you have to decide if you will need a pascal unit or a pascal unit + asm
code. In the first case your command line will be something like:
  
    bin2unit -U myfirstfile.bin mysecondfile.wtf mythirdfile.foo
  
All you have to do is to add the  output file (in this case myfirstfile.pp) to
the uses section of your pascal program. You my want to change the name of the
generated unit:

    bin2unit -U -Nmyresources myfirstfile.bin mysecondfile.wtf mythirdfile.foo

And you will  get an unit called  myresources.pp.  If you need  a pascal + asm 
mixed resources file, then your command line will be:
  
    bin2unit myfirstfile.bin mysecondfile.wtf mythirdfile.foo

or 
  
    bin2unit -Nmyresources myfirstfile.bin mysecondfile.wtf mythirdfile.foo

if you need a  different output name.  In order to use this unit, another step 
is required: you will need to assemble the generated .s files, e.g.:
  
    as.exe -o myfirstfile.o myfirstfile.s
    as.exe -o mysecondfile.o mysecondfile.s
    as.exe -o mythirdfile.o mythirdfile.s

In case of  pascal + asm mixed output, you will have two other parameters that 
are useful in some circumstances:
  
    bin2unit -A2 myfirstfile.bin mysecondfile.wtf mythirdfile.foo
  
Sets the alignment to boundary of 2 (default value is 4)

    bin2unit -Sbss myfirstfile.bin mysecondfile.wtf mythirdfile.foo

Relocates data in the specified section (bss in this example). Default is rodata.
  
The output  is written in the  directory where it is  present the first binary 
file passed to bin2unit. You may want to output files in another directory:
  
    bin2unit myfirstfile.bin mysecondfile.wtf -Oc:\mydirectory
    
All output files will be generated in c:\mydirectory


  
## History log

* ver.0.6  = fixed a bug that afflicted files without path
* ver.0.5  = fixed a warning in the generated asm code
* ver.0.4  = (private release) added output path option
* ver.0.3  = (private release) added multiple files handling
* ver.0.2  = (private release) corrected a bug in path handling
* ver.0.1  = (private release) added some command line switches

