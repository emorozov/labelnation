#!/bin/sh
exec perl -w -x $0 ${1+"$@"} # -*- mode: perl; perl-indent-level: 2; -*-
#!perl -w

### Generic labeling code.  Run with "--help" flag to see options.
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
# If all the labels are the same, then only the first element in this
# array is set, and it is used for each label.
my @Label_Codes       = ();      # User-specified PostScript code...

# User-specified label text, one array of lines for each label.
# If all the labels are the same, then only the first element in this
# array is set, and it is an array(ref) of strings, one string per
# line of text.
my @Label_Lines       = ();      # ... or just lines of label text.

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
  $str =~ s/[\n"' 	]//g;
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

  if (($ntype eq "avery5160") or ($ntype eq "macoll5805"))
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
    $Left_Margin           = 0;
    $Bottom_Margin         = 0;
    $Label_Width           = 0;
    $Label_Height          = 0;
    $Horiz_Space           = 0;
    $Vert_Space            = 0;
    $Horiz_Num_Labels      = 2;
    $Vert_Num_Labels       = 5;
    $Font_Name             = "Times-Roman";
    $Font_Size             = 0;
    die "Can't handle label type \"$otype\" yet\n";
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

    # Even though there isn't any other way to set some of these
    # parameters, we still check that each one is unset before
    # assigning it a value, so that if they are given command-line
    # options or whatever, this code won't override those sources.

    if (($key eq "leftmargin") && ($Left_Margin < 0)) {
      $Left_Margin = &normalize_string ($val);
    }
    elsif (($key eq "bottommargin") && ($Bottom_Margin < 0)) {
      $Bottom_Margin = &normalize_string ($val);
    }
    elsif (($key eq "labelwidth") && ($Label_Width < 0)) {
      $Label_Width = &normalize_string ($val);
    }
    elsif (($key eq "labelheight") && ($Label_Height < 0)) {
      $Label_Height = &normalize_string ($val);
    }
    elsif (($key eq "horizspace") && ($Horiz_Space < 0)) {
      $Horiz_Space = &normalize_string ($val);
    }
    elsif (($key eq "vertspace") && ($Vert_Space < 0)) {
      $Vert_Space = &normalize_string ($val);
    }
    elsif (($key eq "horiznumlabels") && ($Horiz_Num_Labels < 0)) {
      $Horiz_Num_Labels = &normalize_string ($val);
    }
    elsif (($key eq "vertnumlabels") && ($Vert_Num_Labels < 0)) {
      $Vert_Num_Labels = &normalize_string ($val);
    }
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


sub version ()
{
  print "labelnation.pl version $Version.\n";
}


sub types ()
{
  print "Predefined label types:\n";
  print "   Avery-5160 / Maco-LL5805  (30 address labels per page)\n";
  print "   Avery-5167 / Maco-LL8100  (80 return address labels per page)\n";
  print "   Avery-5371 / Maco-LL8550  (10 business cards per page)\n";
}


sub usage ()
{
  &version ();

  print "\n";
  print "More documentation to come!\n";
  print "\n";
  &types ();
  print "\n";
  print "Options:\n";
  print "\n";

  print "  -h, --help, --usage, -?     Show this usage\n";
  print "  --version                   Show version number\n";
  print "  --list-types                Show all predefined label types\n";
  print "  -t, --type TYPE             Generate labels of type TYPE\n";
  print "  -p, --parameter-file FILE   Read label parameters from FILE\n";
  print "  -c, --code-file FILE        Read PostScript code from FILE\n";
  print "  -l, --label-line-file FILE  Get label text lines from FILE\n";
  print "  -d, --delimiter DELIM       (Not yet implemented)\n";
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
  # If this gets set, we encountered unknown options and will exit at
  # the end of this subroutine.
  my $exit_with_admonishment = 0;

  while (my $arg = shift (@ARGV)) 
  {
    if ($arg =~ /^-h$|^-help$|^--help$|^--usage$|^-?$/) {
      &usage ();
      exit (0);
    }
    elsif ($arg =~ /^--version$/) {
      &version ();
      exit (0);
    }
    elsif ($arg =~ /^--list-types$/) {
      &types ();
      exit (0);
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
    elsif ($arg =~ /^-o$|^--outfile$/) {
      $Outfile = &grab_next_argument ($arg);
    }
    else {
      print "Unrecognized option \"$arg\"\n";
      $exit_with_admonishment = 1;
    }
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

  # Set up fonts
  print OUT "/${Font_Name} findfont\n";
  print OUT "${Font_Size} scalefont\n";
  print OUT "setfont\n";

  # Set up subroutines
  my $clipper = &make_clipping_func ();
  print OUT "/labelclip {\n${clipper}\n} def\n";
  # fooo print OUT "/labeldraw {\n${Label_Code}\n} def\n";

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


