#!/bin/sh
exec perl -w -x $0 ${1+"$@"} # -*- mode: perl; perl-indent-level: 2; -*-
#!perl -w

### Label Nation (labelnation.pl): command-line label printing
### Copyright (C) 2000  Karl Fogel <kfogel\@red-bean.com>
### 
### This program is free software; you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation; either version 2 of the License, or
### (at your option) any later version.
### 
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
### 
### You should have received a copy of the GNU General Public License
### along with this program; if not, write to the Free Software
### Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###
### Run with "--help" flag to see options.
### 
### By "label", I mean address labels, business cards, or any other
### rectangles arranged regularly on a printer-ready sheet.

use strict;

################ Globals ###################

my $Type              = "";      # A predefined label type
my $Line_File         = "";      # Text lines for plain label(s)
my $Code_File         = "";      # PostScript code to draw label(s)
my $Param_File        = "";      # Holds new label dimensions
my $Delimiter         = "";      # Separates labels in multi-label files
my $Show_Bounding_Box = 0;       # Set iff --show-bounding-box option

my $Left_Margin       = -1;      # First label from left starts here.
my $Bottom_Margin     = -1;      # First label from bottom starts here.
my $Label_Width       = -1;      # Does not include unused inter-label space.
my $Label_Height      = -1;      # Does not include unused inter-label space.
my $Horiz_Space       = -1;      # Unused inter-label horizontal space.
my $Vert_Space        = -1;      # Unused inter-label vertical space.
my $Horiz_Num_Labels  = -1;      # How many labels across?
my $Vert_Num_Labels   = -1;      # How many labels up and down?
my $Font_Name         = "";      # Defaults to Times-Roman
my $Font_Size         = "";      # Defaults to 12
my $Outfile           = "";      # Defaults to labelnation.ps

# User-specified PostScript code, one string of code for each label.
# Each element of the array is a string of PostScript code, and each
# will be drawn once to a label, then it will cycle again from the
# beginning of the array.  If the sheet holds 30 labels and there are
# 4 different labels defined in this array, then each label will be
# repeated 7 times, with 2 extra labels on the end.  Thus, if all the
# labels on the sheet are to have the same content, then only the
# first element in this array would be set.
my @Label_Codes = ();

# User-specified label text, an array of lines for each label.
# Each element is a reference to an array of text lines -- the lines
# that go on that label.  Behaves otherwise the same as @Label_Codes,
# see above.
my @Label_Lines = ();

# The version number is automatically updated by CVS.
my $Version = '$Revision$';
$Version =~ s/\S+\s+(\S+)\s+\S+/$1/;

my $Inner_Margin = 1;

############## End Globals #################



### Code.

&parse_options ();
&maybe_make_label_codes ();
&print_labels ();



### Subroutines.

sub maybe_make_label_codes ()
{
  if ((scalar (@Label_Codes)) > 0) {
    # We have at least one label-drawing function
    return;
  }
  
  if (! (scalar (@Label_Lines))) {
    # Default to a label showing the empty string
    $Label_Lines[0][0] = "";
  }

  # Else we need to generate PostScript code
  for (my $i = 0; $i < scalar (@Label_Lines); $i++)
  {
    my $reffy = $Label_Lines[$i];
    my @these_lines = @$reffy;
    my $num_lines = scalar (@these_lines);
  
    # For now, we just handle 1 thru 4 lines the same, and punt the rest
    if ($num_lines > 5) {
      die "Oops, I can't handle more than 5 lines of label yet.  Sorry!";
    }
    else
    {
      my $text_margin = $Inner_Margin + 2;
      my $upmost_line_start = (($Label_Height / 5) * $num_lines);
      my $distance_down = ($Label_Height / 6);
      my $this_code = "";
      
      $this_code .= "newpath\n";
      for (my $line = 0; $line < $num_lines; $line++)
      {
        my $this_line = ($upmost_line_start - ($line * $distance_down));
        $this_code .= "$text_margin $this_line\n";
        $this_code .= "moveto\n";
        $this_code .= "(" . $these_lines[$line] . ")\n";
        $this_code .= "show\n";
      }
      $this_code .= "stroke\n";
      $Label_Codes[$i] = $this_code;
    }
  }
}


sub dedelimit_string ()
{
  my $str = shift;
  my $ignore = "";
  $str =~ s/[\n"' 	]//g;
  $ignore =~ s/[\n" 	]//g;  # Placate Emacs indentation & font-lock.
  return $str;
}


sub normalize_string ()
{
  my $str = shift;
  $str = &dedelimit_string ($str);
  $str = lc ($str);
  $str =~ s/[-_.]//g;
  return $str;
}


sub set_parameters_for_type ()
{
  my $otype = shift;
  my $ntype = &normalize_string ($otype);

  if ($ntype eq "avery5261")  # don't know Maco's number for these yet
  {
    # Large and wide address labels, 20 per page
    $Left_Margin           = 11.25;
    $Bottom_Margin         = 16;
    $Label_Width           = 270;
    $Label_Height          = 72;
    $Horiz_Space           = 20;
    $Vert_Space            = 0;
    $Horiz_Num_Labels      = 2;
    $Vert_Num_Labels       = 10;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 12;
  }
  elsif (($ntype eq "avery5160")
         or ($ntype eq "avery6245")
         or ($ntype eq "macoll5805"))
  {
    # Large address labels, 30 per page
    $Left_Margin           = 11.25;
    $Bottom_Margin         = 16;
    $Label_Width           = 180;
    $Label_Height          = 72;
    $Horiz_Space           = 20;
    $Vert_Space            = 0;
    $Horiz_Num_Labels      = 3;
    $Vert_Num_Labels       = 10;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 12;
  }
  elsif (($ntype eq "avery5167") or ($ntype eq "macoll8100"))
  {
    # Small address labels, 80 per page
    $Left_Margin           = 14;
    $Bottom_Margin         = 17;
    $Label_Width           = 126;
    $Label_Height          = 36;
    $Horiz_Space           = 22.5;
    $Vert_Space            = 0;
    $Horiz_Num_Labels      = 4;
    $Vert_Num_Labels       = 20;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 7;
  }
  elsif (($ntype eq "avery5371") or ($ntype eq "macoll8550"))
  {
    # Business cards
    $Left_Margin           = 48;
    $Bottom_Margin         = 16;
    $Label_Width           = 253.5;
    $Label_Height          = 145.3;
    $Horiz_Space           = 0;
    $Vert_Space            = 0;
    $Horiz_Num_Labels      = 2;
    $Vert_Num_Labels       = 5;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 0;
  }
  elsif ($ntype eq "kffweekly") # My own private labels
  {
    # Weekly calendar, to fit on pages 252x486
    $Left_Margin           = 47;
    $Bottom_Margin         = 11;
    $Label_Width           = 240;
    $Label_Height          = 60;
    $Horiz_Space           = 0;
    $Vert_Space            = 5;
    $Horiz_Num_Labels      = 1;
    $Vert_Num_Labels       = 7;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 12;
  }
  else {
    die "Unknown label type \"$otype\"\n";
  }
}


sub show_parameters ()
{
  print "LeftMargin      $Left_Margin\n";
  print "BottomMargin    $Bottom_Margin\n";
  print "LabelWidth      $Label_Width\n";
  print "LabelHeight     $Label_Height\n";
  print "HorizSpace      $Horiz_Space\n";
  print "VertSpace       $Vert_Space\n";
  print "HorizNumLabels  $Horiz_Num_Labels\n";
  print "VertNumLabels   $Vert_Num_Labels\n";
  print "FontName        $Font_Name\n";
  print "FontSize        $Font_Size\n";
}


sub parse_param_file ()
{
  my $cfile = shift;

  open (CTL, "<$cfile");
  while (<CTL>)
  {
    # Ignore comment lines
    if ($_ =~ /^\s*\#/) {
       next; 
    }

    my ($key, $val) = split /[ 	]+/;

    $key = &normalize_string ($key);
    if (defined ($val)) {
      $val = &dedelimit_string ($val);
    }

    if ($key eq "leftmargin") {
      $Left_Margin = &normalize_string ($val);
    }
    elsif ($key eq "bottommargin") {
      $Bottom_Margin = &normalize_string ($val);
    }
    elsif ($key eq "labelwidth") {
      $Label_Width = &normalize_string ($val);
    }
    elsif ($key eq "labelheight") {
      $Label_Height = &normalize_string ($val);
    }
    elsif ($key eq "horizspace") {
      $Horiz_Space = &normalize_string ($val);
    }
    elsif ($key eq "vertspace") {
      $Vert_Space = &normalize_string ($val);
    }
    elsif ($key eq "horiznumlabels") {
      $Horiz_Num_Labels = &normalize_string ($val);
    }
    elsif ($key eq "vertnumlabels") {
      $Vert_Num_Labels = &normalize_string ($val);
    }
    # Remaining ones should never override command-line
    elsif (($key eq "fontname") && (! $Font_Name)) {
      $Font_Name = $val;
    }
    elsif (($key eq "fontsize") && (! $Font_Size)) {
      $Font_Size = $val;
    }
    elsif (($key eq "outfile") && (! $Outfile)) {
      $Outfile = $val;
    }
    else {
      print "Unknown parameter line \"$_\"\n";
    }
    
  }
  close (CTL);
}


sub parse_code_file ()
{
  my $file = shift;
  my $i = 0;

  open (F, "<$file");
  while (<F>) {
    chomp;
    if ($_ eq $Delimiter) {
      $i++;
    } else {
      $Label_Codes[$i] .= "$_\n";
    }
  }
  close (F);
}


sub parse_line_file ()
{
  my $file = shift;
  my $accum = [];
  my $i = 0;
  my $j = 0;

  open (F, "<$file");
  while (<F>) {
    chomp;
    if ($_ eq $Delimiter) {
      $Label_Lines[$i] = $accum;
      $accum = [];
      $j = 0;
      $i++;
    }
    else {
      $$accum[$j++] = $_;
    }
  }
  close (F);

  $Label_Lines[$i] = $accum if ($j > 0);
}


sub usage ()
{
  &version ();
  print "\n";

  &explain ();
  print "\n";

  &types ();
  print "\n";

  print "Options:\n";
  print "\n";

  print "  -h, --help, --usage, -?     Show this usage\n";
  print "  --version                   Show version number\n";
  print "  --explain                   Show instructions (lots of output!)\n";
  print "  --list-types                Show all predefined label types\n";
  print "  -t, --type TYPE             Generate labels of type TYPE\n";
  print "  -p, --parameter-file FILE   Read label parameters from FILE\n";
  print "  -c, --code-file FILE        Get PostScript code from FILE\n";
  print "  -l, --label-line-file FILE  Get label text lines from FILE\n";
  print "  -d, --delimiter DELIM       Labels separated by DELIM\n";
  print "  --show-bounding-box         Print rectangle around each label\n";
  print "                                (recommended for testing only)\n";
  print "  --font-name NAME            Use PostScript font FONT\n";
  print "  --font-size SIZE            Scale font to SIZE\n";
  print "  -o, --outfile FILE          Output to FILE (\"-\" means stdin)\n";
}


sub grab_next_argument ()
{
  my $arg = shift;
  my $next_arg = shift (@ARGV) || die "$arg needs argument.\n";
  return $next_arg;
}


sub parse_options ()
{
  my $exit_cleanly = 0;
  my $show_parameters = 0;

  # If this gets set, we encountered unknown options and will exit at
  # the end of this subroutine.
  my $exit_with_admonishment = 0;

  while (my $arg = shift (@ARGV)) 
  {
    if ($arg =~ /^-h$|^-help$|^--help$|^--usage$|^-?$/) {
      &usage ();
      $exit_cleanly = 1;
    }
    elsif ($arg =~ /^--version$/) {
      &version ();
      $exit_cleanly = 1;
    }
    elsif ($arg =~ /^--list-types$/) {
      &types ();
      $exit_cleanly = 1;
    }
    elsif ($arg =~ /^--explain$/) {
      &explain ();
      $exit_cleanly = 1;
    }
    elsif ($arg =~ /^--show-parameters$/) {
      $show_parameters = 1;
    }
    elsif ($arg =~ /^-t$|^--type$/) {
      $Type = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-p$|^--parameter-file$/) {
      # kff todo: what if both param file and type given?
      $Param_File = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-c$|^--code-file$/) {
      $Code_File = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-l$|^--label-line-file$/) {
      $Line_File = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-d$|^--delimiter$/) {
      $Delimiter = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^--font-name$/) {
      $Font_Name = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^--font-size$/) {
      $Font_Size = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^--show-bounding-box$/) {
      $Show_Bounding_Box = 1;
    }
    elsif ($arg =~ /^--left-margin$/) {
      $Left_Margin = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^--bottom-margin$/) {
      $Bottom_Margin = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-o$|^--outfile$/) {
      $Outfile = &grab_next_argument ($arg);
    }
    else {
      print "Unrecognized option \"$arg\"\n";
      $exit_with_admonishment = 1;
    }
  }

  if ($exit_cleanly) {
    exit (0);
  }

  # Do file parsing _after_ command line options have been processed
  if ($Type) {
    &set_parameters_for_type ($Type);
  }
  if ($Param_File) {
    &parse_param_file ($Param_File);
  }
  if ($Code_File) {
    &parse_code_file ($Code_File);
  }
  if ($Line_File) {
    # kff todo: what if have both line and code file??
    &parse_line_file ($Line_File);
  }

  if ($show_parameters) {
    &show_parameters ();
    exit (0);
  }

  # Check that required parameters have indeed been found.
  if ($Left_Margin < 0) {
    print "missing required left-margin parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Bottom_Margin < 0) {
    print "missing required bottom-margin parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Label_Width < 0) {
    print "missing required label-width parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Label_Height < 0) {
    print "missing required label-height parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Horiz_Space < 0) {
    print "missing required horiz-space parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Vert_Space < 0) {
    print "missing required vert-space parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Horiz_Num_Labels < 0) {
    print "missing required horiz-num-labels parameter\n";
    $exit_with_admonishment = 1;
  }
  if ($Vert_Num_Labels < 0) {
    print "missing required vert-num-labels parameter\n";
    $exit_with_admonishment = 1;
  }

  # Set up defaults for things that could reasonably be omitted.
  if (! $Font_Name) {
    $Font_Name = "Times-Roman";
  }
  if (! $Font_Size) {
    $Font_Size = "12";
  }
  if (! $Outfile) {
    $Outfile = "labelnation.ps";
  }

  if ($exit_with_admonishment) {
    print "Run \"labelnation.pl --help\" to see usage.\n";
    exit (1);
  }
}


sub make_clipping_func ()
{
  my $clipper = "";

  my $upper_bound = $Label_Height - $Inner_Margin;
  my $right_bound = $Label_Width  - $Inner_Margin;

  $clipper .= "newpath\n";
  $clipper .= "$Inner_Margin $Inner_Margin moveto\n";
  $clipper .= "$right_bound $Inner_Margin lineto\n";
  $clipper .= "$right_bound $upper_bound lineto\n";
  $clipper .= "$Inner_Margin $upper_bound lineto\n";
  $clipper .= "closepath\n";
  $clipper .= "clip\n";
  $clipper .= "stroke\n" if ($Show_Bounding_Box);

  return $clipper;
}


sub print_labels ()
{
  open (OUT, ">$Outfile") or die ("Unable to open $Outfile ($!)");

  # Start off with standard Postscript header
  print OUT "%!PS-Adobe-1.0\n";

  # Set up fonts
  print OUT "/${Font_Name} findfont\n";
  print OUT "${Font_Size} scalefont\n";
  print OUT "setfont\n";

  # Set up subroutines
  my $clipper = &make_clipping_func ();
  print OUT "/labelclip {\n${clipper}\n} def\n";

  print OUT "\n";

  print OUT "$Left_Margin\n";
  print OUT "$Bottom_Margin\n";
  print OUT "translate\n";
  print OUT "\n";

  # Index into array of PostScript drawing chunks
  my $code_idx = 0;

  # Outer loop is X coordinate, inner is Y
  for (my $x = 0; $x < $Horiz_Num_Labels; $x++)
  {
    my $this_x_step = ($x * ($Label_Width  + $Horiz_Space));
    
    for (my $y = 0; $y < $Vert_Num_Labels; $y++)
    {
      my $this_y_step = ($y * ($Label_Height + $Vert_Space));
      my $this_code = $Label_Codes[$code_idx];
      
      print OUT "gsave\n";
      print OUT "$this_x_step $this_y_step\n";
      print OUT "translate\n";
      print OUT "labelclip\n";
      print OUT "$this_code\n";
      print OUT "grestore\n";
      print OUT "\n";

      $code_idx = ($code_idx + 1) % (scalar (@Label_Codes));
    }
  }
  
  print OUT "showpage\n";
  
  close (OUT);
}


# Print version number.
sub version ()
{
  print "labelnation.pl version $Version.\n";
}


# Print all predefined label types
sub types ()
{
  print "Predefined label types:\n";
  print "   Avery-5160 / Avery-6245 / Maco-LL5805  (30 labels per page)\n";
  print "   Avery-5167 / Maco-LL8100               (80 labels per page)\n";
  print "   Avery-5371 / Maco-LL8550               (10 bcards per page)\n";
}


# Print a general explanation of how this program works.
sub explain ()
{
  print <<END;
LabelNation is a program for making labels.  By "label", I mean
address labels, business cards, or anything else involving
regularly-arranged rectangles on a printer-ready sheet.  You can even
use it to make a calendar (that took some work, though).

Here's the basic concept: you tell LabelNation what text you want on
each label (i.e., each rectangle).  You can specify plain lines of
text, or even arbitrary PostScript code.  You also tell it what kind
of labels it should print for.  LabelNation takes all this information
and produces a PostScript file, which you then send to your printer.

Of course, you'll need a PostScript printer (or a PostScript filter,
such as GNU GhostScript), and a sheet of special peel-off label paper
in the tray.  Such paper is widely available at office supply stores.
Two companies that offer it are Avery Dennison (www.averydennison.com)
and Maco (www.maco.com).  This is not a recommendation or an
endorsement -- Avery and Maco are simply the names I've seen.

PostScript viewing software also helps, so you can see what your
labels look like before you print.

How To Use It:
==============

Let's start with an example.  If you wanted to print a sheet of return
address labels using the Avery 5167 standard (80 small labels per
page), you might invoke LabelNation like this:

   prompt\$ labelnation.pl -t avery5167 -l myaddress.txt -o myaddress.ps

The "-t" stands for "type", followed by one of the standard predefined
label types.  The "-l" stands for "label lines", followed by the name
of a file containing the lines of text you want written on the label.
The "-o" specifies the output file, which is what you'll print to get
the labels.

Here is a sample label lines file:

        J. Random User
        1423 W. Rootbeer Ave
        Chicago, IL 60622
        USA

Note that the indentation is significant -- the farther you indent a
line, the more whitespace will be between it and the left edge of the
label.  Three spaces is a typical indentation.  Also note that blank
lines are ignored -- they will be printed just like regular text.

You can have anywhere from 1 to 5 lines on a label.


How To Discover The Predefined Label Types:
===========================================

To see a list of all known label types, run

   prompt\$ labelnation.pl --list-types
   Predefined label types:
      Avery-5160 / Avery-6245 / Maco-LL5805  (30 labels per page)
      Avery-5167 / Maco-LL8100               (80 labels per page)
      [etc...]

Note that when you're specifying a label type, you can omit the
capitalization and the hyphen (or you can leave them on -- LabelNation
will recognize the type either way).

A bit farther on, you'll learn how to define your own label types, in
case none of the built-in ones are suitable.


What To Do If The Text Is A Little Bit Off From The Labels:
===========================================================

Printers vary -- the label parameters that work for me might not be
quite right for your hardware.  Correcting the problem may merely be a
matter of adjusting the bottom and/or left margin (that is, the
distance from the bottom or left edge of the page to the first row or
column, respectively).

The two options to do this are

   prompt\$ labelnation.pl --bottom-margin N --left-margin N ...

where N is a number of PostScript points, each being 1/72 of an inch.
(Of course, you don't have to use the two options together, that's
just how it is in this example.)  The N you specify does not add to
the predefined quantity, but rather replaces it.

In order to know where you're starting from, you can ask LabelNation
to show you the parameters for a given label type:

   prompt\$ labelnation.pl -t avery5167 --show-parameters
   LeftMargin      14
   BottomMargin    17
   LabelWidth      126
   LabelHeight     36
   HorizSpace      22.5
   VertSpace       0
   HorizNumLabels  4
   VertNumLabels   20
   FontName        Times-Roman
   FontSize        7

The first two parameters are usually the only ones you need to look
at, although the others may come in handy when you're defining your
own parameter files.  Which brings me to the next subject...


How To Print Labels That Aren't One Of The Predefined Standards:
================================================================

Use the -p option to tell LabelNation to use a parameter file.  A
parameter file consists of lines of the form

   PARAMETER   VALUE
   PARAMETER   VALUE
   PARAMETER   VALUE
   ...

you can see valid parameter names by running

   prompt\$ labelnation.pl -t avery5167 --show-parameters

as mentioned earlier (it doesn't have to be avery5167, it can be any
built-in type).  Keep in mind that a "parameter file" is for
specifying the dimensions and arrangement of the labels on the sheet,
*not* for specifying the content you want printed on those labels.


How To Use Arbitrary Postscript Code To Draw Labels:
====================================================

Do you know how to write PostScript?  Do you want to be a Power User
of LabelNation?  Then this section is for you:

Instead of passing a file of label lines with the "-l" options, pass a
file containing PostScript code using the "-c" option.

The code will be run in a translated coordinate space, so 0,0 is at
the bottom left corner of each label in turn.  Also, clipping will be
in effect, so you can't draw past the edges of a label.  Obviously,
you will have to experiment a lot using your favorite PostScript
viewing software before you're ready to print.


How To Print A Variety Of Addresses On A Sheet:
===============================================

In a label lines file (or a PostScript code file), you can define
multiple label contents.  Each label's content must be separated from
the previous label by a delimiter of your choice.  For example, if the
delimiter is "XXX", then you might invoke LabelNation like
so

   prompt\$ labelnation.pl -d "XXX" -t avery5167 -l 2addrs.txt -o 2addrs.ps

where 2addrs.txt contains this

        J. Random User
        1423 W. Rootbeer Ave
        Chicago, IL 60622
        USA
   XXX
        William Lyon Phelps III
        27 Rue d'Agonie
        Paris, France
   XXX

(remember that all my examples are indented three spaces in this help
message, so the content above is indented only three spaces in the
file, while the XXX delimiters are not really indented at all). 


How To Report A Bug:
====================

Check http://www.red-bean.com/labelnation to make sure you have the
latest version (perhaps your bug has been fixed).  Else, email
<bug-labelnation\@red-bean.com>.

Copyright:
==========

    Label Nation (labelnation.pl): command-line label printing
    Copyright (C) 2000  Karl Fogel <kfogel\@red-bean.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

END
}

