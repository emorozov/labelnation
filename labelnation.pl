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
my $Infile            = "";      # Holds PostScript code or text lines
my $Line_Input        = 0;       # One kind of input $Infile can hold.
my $Code_Input        = 0;       # Another kind of input $Infile can hold.
my $Param_File        = "";      # Holds label dimensions
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

# The version number is automatically updated by CVS.
my $Version = '$Revision$';
$Version =~ s/\S+\s+(\S+)\s+\S+/$1/;

my $Inner_Margin = 1;

############## End Globals #################



### Code.

&parse_options ();
# &maybe_make_label_codes ();
&print_labels ();



### Subroutines.

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
  my @params;

  # Don't know Maco's number for Avery 5161/5261 yet...
  if (($ntype eq "avery5161") or ($ntype eq "avery5261"))
  {
    # Large and wide address labels, 20 per page
    $params[0] = 11.25;           # Left_Margin
    $params[1] = 16;              # Bottom_Margin
    $params[2] = 270;             # Label_Width
    $params[3] = 72;              # Label_Height
    $params[4] = 20;              # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 2;               # Horiz_Num_Labels
    $params[7] = 10;              # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 12;              # Font_Size
  }
  elsif (($ntype eq "avery5160")
         or ($ntype eq "avery6245")
         or ($ntype eq "macoll5805"))
  {
    # Large address labels, 30 per page
    $params[0] = 11.25;           # Left_Margin
    $params[1] = 16;              # Bottom_Margin
    $params[2] = 180;             # Label_Width
    $params[3] = 72;              # Label_Height
    $params[4] = 20;              # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 3;               # Horiz_Num_Labels
    $params[7] = 10;              # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 12;              # Font_Size
  }
  elsif (($ntype eq "avery5167") or ($ntype eq "macoll8100"))
  {
    # Small address labels, 80 per page
    $params[0] = 14;              # Left_Margin
    $params[1] = 17;              # Bottom_Margin
    $params[2] = 126;             # Label_Width
    $params[3] = 36;              # Label_Height
    $params[4] = 22.5;            # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 4;               # Horiz_Num_Labels
    $params[7] = 20;              # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 7;               # Font_Size
  }
  elsif (($ntype eq "avery5371") or ($ntype eq "macoll8550"))
  {
    # Business cards
    $params[0] = 48;              # Left_Margin
    $params[1] = 16;              # Bottom_Margin
    $params[2] = 253.5;           # Label_Width
    $params[3] = 145.3;           # Label_Height
    $params[4] = 0;               # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 2;               # Horiz_Num_Labels
    $params[7] = 5;               # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 0;               # Font_Size
  }
  elsif ($ntype eq "avery5263")
  {
    # Big mailing labels, 10 per page.  Usually the TO address goes
    # on these.
    $params[0] = 48;              # Left_Margin
    $params[1] = 31;              # Bottom_Margin
    $params[2] = 253.5;           # Label_Width
    $params[3] = 145.3;           # Label_Height
    $params[4] = 0;               # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 2;               # Horiz_Num_Labels
    $params[7] = 5;               # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 20;              # Font_Size
  }
  elsif (($ntype eq "?avery6464?") or ($ntype eq "?maco????"))
  {
    # kff todo: got some labels from CollabNet HQ today, don't know
    # the brand numbers yet.
    $params[0] = 11;              # Left_Margin
    $params[1] = 38;              # Bottom_Margin
    $params[2] = 288.5;           # Label_Width
    $params[3] = 238.2;           # Label_Height
    $params[4] = 11.3;            # Horiz_Space
    $params[5] = 0;               # Vert_Space
    $params[6] = 2;               # Horiz_Num_Labels
    $params[7] = 3;               # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 0;               # Font_Size
  }
  elsif ($ntype eq "kffweekly") # My own private labels
  {
    # Weekly calendar, to fit on pages 252x486
    $params[0] = 47;              # Left_Margin
    $params[1] = 11;              # Bottom_Margin
    $params[2] = 240;             # Label_Width
    $params[3] = 60;              # Label_Height
    $params[4] = 0;               # Horiz_Space
    $params[5] = 5;               # Vert_Space
    $params[6] = 1;               # Horiz_Num_Labels
    $params[7] = 7;               # Vert_Num_Labels
    $params[8] = "Times-Roman";   # Font_Name
    $params[9] = 12;              # Font_Size
  }
  else {
    die "Unknown label type \"$otype\"\n";
  }

  # Set up standard params, but preserving manual overrides:
  $Left_Margin      = $params[0]    if ($Left_Margin      < 0);
  $Bottom_Margin    = $params[1]    if ($Bottom_Margin    < 0);
  $Label_Width      = $params[2]    if ($Label_Width      < 0);
  $Label_Height     = $params[3]    if ($Label_Height     < 0);
  $Horiz_Space      = $params[4]    if ($Horiz_Space      < 0);
  $Vert_Space       = $params[5]    if ($Vert_Space       < 0);
  $Horiz_Num_Labels = $params[6]    if ($Horiz_Num_Labels < 0);
  $Vert_Num_Labels  = $params[7]    if ($Vert_Num_Labels  < 0);
  $Font_Name        = $params[8]    if ($Font_Name        eq "");
  $Font_Size        = $params[9]    if ($Font_Size        eq "");
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
      $Left_Margin = &dedelimit_string ($val);
    }
    elsif ($key eq "bottommargin") {
      $Bottom_Margin = &dedelimit_string ($val);
    }
    elsif ($key eq "labelwidth") {
      $Label_Width = &dedelimit_string ($val);
    }
    elsif ($key eq "labelheight") {
      $Label_Height = &dedelimit_string ($val);
    }
    elsif ($key eq "horizspace") {
      $Horiz_Space = &dedelimit_string ($val);
    }
    elsif ($key eq "vertspace") {
      $Vert_Space = &dedelimit_string ($val);
    }
    elsif ($key eq "horiznumlabels") {
      $Horiz_Num_Labels = &dedelimit_string ($val);
    }
    elsif ($key eq "vertnumlabels") {
      $Vert_Num_Labels = &dedelimit_string ($val);
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
  print "  -i, --infile                Take input from FILE\n";
  print "  -l, --line-input            Infile contains label text lines\n";
  print "  -c, --code-input            Infile contains PostScript code\n";
  print "  -d, --delimiter DELIM       Labels separated by DELIM\n";
  print "  --show-bounding-box         Print rectangle around each label\n";
  print "                                (recommended for testing only)\n";
  print "  --font-name NAME            Use PostScript font FONT\n";
  print "  --font-size SIZE            Scale font to SIZE\n";
  print "  -o, --outfile FILE          Output to FILE (\"-\" means stdout)\n";
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
      $Param_File = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-i$|^--infile$/) {
      $Infile = &grab_next_argument ($arg);
    }
    elsif ($arg =~ /^-l$|^--line-input$/) {
      $Line_Input = 1;
    }
    elsif ($arg =~ /^-c$|^--code-input$/) {
      $Code_Input = 1;
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
  if ($Code_Input && $Line_Input)
  {
    print "Cannot use both -l and -c\n";
    $exit_with_admonishment = 1;
  }
  if ((! $Code_Input) && (! $Line_Input))
  {
    print "Must use one of -l or -c\n";
    $exit_with_admonishment = 1;
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
  open (IN, "<$Infile") or die ("trouble opening $Infile for reading ($!)");
  open (OUT, ">$Outfile") or die ("trouble opening $Outfile for writing ($!)");

  # Start off with standard Postscript header
  print OUT "%!PS-Adobe-1.0\n";

  # Set up fonts
  print OUT "/${Font_Name} findfont\n";
  print OUT "${Font_Size} scalefont\n";
  print OUT "setfont\n";

  # Set up subroutines
  my $clipfunc = &make_clipping_func ();
  print OUT "/labelclip {\n${clipfunc}\n} def\n";

  print OUT "\n";

  # Set up some loop vars.
  my @label_lines;            # Used only for $Line_Input;
  my $line_idx = 0;           # Used only for $Line_Input;
  my $code_accum;             # Used for both $Line_Input and $Code_Input;
  my $x = 0;                  # Horiz position (by label)
  my $y = 0;                  # Vertical position (by label)
  my $page_number = 1;        # Do you really need a comment?
  my $been_there = 0;         # For handling single-label-text input

  while (<IN>)
  {
    chomp;

    if ($_ eq $Delimiter)
    {
    print_what_have_so_far:
      if ($Line_Input)
      {
        my $num_lines = scalar (@label_lines);
   
        my $text_margin = $Inner_Margin + 2;
        # kff todo: need to be more sophisticated about divining the
        # font sizes and acting accordingly, here.
        my $upmost_line_start = (($Label_Height / 5) * $num_lines);
        my $distance_down = ($Label_Height / 6);
        
        $code_accum .= "newpath\n";
        for (my $line = 0; $line < $num_lines; $line++)
        {
          my $this_line = ($upmost_line_start - ($line * $distance_down));
          $code_accum .= "$text_margin $this_line\n";
          $code_accum .= "moveto\n";
          $code_accum .= "(" . $label_lines[$line] . ")\n";
          $code_accum .= "show\n";
        }
        $code_accum .= "stroke\n";
      }

      if (($x == 0) && ($y == 0))
      {
        print OUT "%%Page: labels $page_number\n\n";
        print OUT "%%BeginPageSetup\n";
        print OUT "$Left_Margin ";
        print OUT "$Bottom_Margin ";
        print OUT "translate\n";
        print OUT "%%EndPageSetup\n";
      }
      
      # Print the label, clipped and translated appropriately.
      my $this_x_step = ($x * ($Label_Width  + $Horiz_Space));
      my $this_y_step = ($y * ($Label_Height + $Vert_Space));
      print OUT "gsave\n";
      print OUT "$this_x_step $this_y_step\n";
      print OUT "translate\n";
      print OUT "labelclip\n";
      print OUT "$code_accum";
      print OUT "grestore\n";
      print OUT "\n";

      # Increment, and maybe cross a column or page boundary.
      $y++;
      if ($y >= $Vert_Num_Labels)
      {
        $y = 0;
        $x++;
      }
      if ($x >= $Horiz_Num_Labels) 
      {
        $x = 0;
        $page_number++;
        print OUT "showpage\n";
      }

      # Reset everyone.
      if ($Delimiter) {
        undef @label_lines;
        $line_idx = 0;
        $code_accum = "";
      }
    }
    elsif ($Line_Input)
    {
      $label_lines[$line_idx++] = $_;
    }
    elsif ($Code_Input)
    {
      $code_accum .= "$_";
      $code_accum .= "\n";
    }
  }
  
  # You are not going to believe this... let me explain:
  # 
  # We want to handle input files containing only a single label, that
  # is, input files with no delimiter, so every line that appears in
  # the input is part of the one label text.  Then this label is
  # mapped across the whole page, so we get a single page with the
  # same label on it.  That way it's as convenient to produce return
  # address labels as to generate outgoing mailing list sheets.
  #
  # Since there's no delimiter, we just jump straight to the printing
  # part in the `while' loop above, and let it increment x and y as it
  # normally does.  So the conditional below behaves like the guard of
  # a `for' loop, except it's after the fact, and it shares its body
  # with the file-reading loop.  We use $been_there to stop after one
  # page, otherwise it would go on forever. 
  #
  if ((! $Delimiter)
      && (! ($y >= $Vert_Num_Labels))
      && (! ($x >= $Horiz_Num_Labels))
      && (! ($been_there && ($x == 0) && ($y == 0))))
  {
    $been_there = 1;
    goto print_what_have_so_far;
  }

  unless (($x == 0) && ($y == 0)) {
    print OUT "showpage\n";
  }
  
  close (OUT);
}


# Print version number.
sub version ()
{
  print "labelnation.pl version $Version\n";
}


# Print all predefined label types
sub types ()
{
  print "Predefined label types:\n";
  print "   Avery-5263                             (10 labels per page)\n";
  print "   Avery-5161 / Avery-5261                (20 labels per page)\n";
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

Let's start with return address labels.  If you wanted to print a
sheet of them using the Avery 5167 standard (80 small labels per
page), you might invoke LabelNation like this:

   prompt\$ labelnation.pl -t avery5167 -i myaddress.txt -l -o myaddress.ps

The "-t" stands for "type", followed by one of the standard predefined
label types.  The "-i" means "input file", that is, where to take the
label data from.  The "-l" stands for "lines input", meaning that the
format of the incoming data is lines of text (as opposed to PostScript
code).  The "-o" specifies the output file, which you'll print to get
the labels.

Here is a sample label lines file:

        J. Random User
        1423 W. Rootbeer Ave
        Chicago, IL 60622
        USA

Note that the indentation is significant -- the farther you indent a
line, the more whitespace will be between it and the left edge of the
label.  Three spaces is a typical indentation.  Also note that blank
lines are significant -- they are printed like any other text.

You can have anywhere from 1 to 5 lines on a label.


How To Print A Variety Of Addresses:
====================================

An input file can also define many different labels (this is useful if
you're running a mailing list, for example).  In that case, instead of
iterating one label over an entire sheet, LabelNation will print each
label once, using as many sheets as necessary, leaving the unused
remainder blank.

To print many labels at once, you must pass a delimiter with the "-d"
flag.  The delimiter separates each label from the next.  For
example, if you use a delimiter of "XXX", then you might invoke
LabelNation like so

   prompt\$ labelnation.pl -d "XXX" -t avery5167 -l -i addrs.txt -o addrs.ps

where addrs.txt contains this

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
message, so the content above is actually indented only three spaces
in the file, while the XXX delimiters are not indented at all). 


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

You can see valid parameter names by running

   prompt\$ labelnation.pl -t avery5167 --show-parameters

as mentioned earlier (it doesn't have to be avery5167, it can be any
built-in type).  Keep in mind that a "parameter file" is for
specifying the dimensions and arrangement of the labels on the sheet,
*not* for specifying the content you want printed on those labels.


How To Use Arbitrary Postscript Code To Draw Labels:
====================================================

If your input file contains PostScript code to draw the label(s),
instead of lines of label text, then pass the "-c" (code) option
instead of "-l".

The PostScript code will be run in a translated coordinate space, so
0,0 is at the bottom left corner of each label in turn.  Also,
clipping will be in effect, so you can't draw past the edges of a
label.  Normally, you will have to experiment a lot to get things just
right.

You can still print multiple, different labels at
once -- delimiters work just as well in code files as in linetext
files.


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

