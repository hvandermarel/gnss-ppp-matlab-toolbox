#!/usr/bin/perl -w
#
#   xtrNRCAN.pl
#   ----------
#   This script scans NRCAN summary files and extracts useful results.
#
#   (c) 2018-2024 Hans van der Marel, Delft University of Technology
#   
#   Created  10 June 2018 by Hans van der Marel
#   Modified  1 July 2019 by Hans van der Marel
#             - adapted to the new SUMMARY file format
#            12 April 2020 by Hans van der Marel
#             - fixed bug in reading antenna height (ARP)
#             5 July 2020 by Hans van der Marel
#             - extract receiver and antenna type, software version, system
#               and number of epochs
#            10 July 2023 by Hans van der Marel
#             - epoch and observation totals now include all systems
#             - improved IAR parsing
#             3 June 2023 by Hans van der Marel
#             - extract sp3 product type (FIN,RAP,ULT)
#            24 June 2025 by Hans van der Marel
#             - IAR format was changed, added new variant

use vars qw( $VERSION );
use File::Basename;
use Time::Local 'timegm_nocheck';
use Getopt::Long;

$VERSION = 20240603;

# -------------------------------------------------------------------------------
# Process input arguments and options
# -------------------------------------------------------------------------------

# Get command line arguments

my %Config = (
    verbose      =>  0 ,
    legacy       =>  0 ,
);  

Getopt::Long::Configure( "prefix_pattern=(-)" );
$Result = GetOptions( \%Config,
                      qw(
                        verbose|v
                        legacy|l
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV );

if( $Config{help} )
{
    Syntax();
    exit();
}

$debug=$Config{verbose};

# Expand the file names (if not done already by the shell)

@allfiles=();
foreach $argument (@ARGV) {
  push(@allfiles,glob($argument));
}


# -------------------------------------------------------------------------------
# Print table with extracted data
# -------------------------------------------------------------------------------

print "name,obsfile,Lat(dms),Lon(dms),H(m),sN,sE,SU,cNE,cNU,cEU,X(m),Y(m),Z(m),sX,sY,SZ,cXY,cXZ,cYZ,start,stop,interval,antheight,anttype,rectype,syst,prod,iar,nepoused,nepoavail,nepoexp,nobs,notrk,rejected,version\n";
    
 
foreach $sumfile ( sort (@allfiles)) {
   #($sumtxt,%sumdata) = &ScanSumFile($sumfile);
   if ( $Config{legacy} ) {
     $sumtxt = &ScanLegacySumFile($sumfile);
   } else {
     $sumtxt = &ScanSumFile($sumfile);
   }
   print "$sumtxt\n";
}


exit;


# ----------------------------------------------------------------------------
# Subroutines

sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Extract coordinate data from NRCAN summary files and into comma separated fields.
Syntax: 
    $Script [-v] [-h|?] file-patterns

    -v[erbose]......Verbose mode (extra debugging output). 
    -l[egacy] ......Read legacy SUM file format. 
    -?|h|help.......This help.

    file-patterns...Input files (wildcards and csh style globbing allowed).

Example:
  $Script NRCAN/*.sum

(c) 2018-2024 by Hans van der Marel (H.vanderMarel\@tudelft.nl)
Delft University of Technology.
EOT

}


sub ScanSumFile{

  # Scan NRCAN Summary file

  my($sumfile) = @_;
  my($sumtxt)="";
  my(%sumdata);

  my(@fields);

  open(SUMFILE,"$sumfile") ||  die ("Error opening $sumfile\n");


  # Scan summary file
  while (<SUMFILE>) {
    chomp($_);
    last if ( /^POS / );
    if ( /^VER / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{ver} ) = ( $_ =~ /^VER\s+(\S+)/ ); 
    }
    if ( /^RNX / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxfile} ) = ( $_ =~ /^RNX\s+(\S+)/ ); 
    }
    if ( /^MKR / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{marker} ) = ( $_ =~ /^MKR\s+(\S+)/ ); 
    }
    if ( /^BEG / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxstart} ) = ( $_ =~ /^BEG\s+(\S+\s\S+)/ ); 
    }
    if ( /^END / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxend} ) = ( $_ =~ /^END\s+(\S+\s\S+)/ ); 
    }
    if ( /^INT / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxinterval} ) = ( $_ =~ /^INT\s+(\S+)/ ); 
    }
    if ( /^EPO / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{numepochs} ) = join(",",( $_ =~ /^EPO\s+(\d+)\s+(\d+)\s(\d+)/ )); 
    }
    if ( /^SP3 / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{prod} ) = ( $_ =~  /^SP3\s+(\S.*)$/ ); 
    }
    if ( /^REC / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{receiver} ) = ( $_ =~  /^REC\s+(\S.*)$/ ); 
    }
    if ( /^ANT / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{antenna} ) = ( $_ =~  /^ANT\s+(\S.*)$/ ); 
    }
    if ( /^ARP / ) {
       print "$_\n" if ($debug); 
       ( $sumdata{antheight} ) = ( $_ =~  /^ARP\s+[+-]?[\d\.]+\s+[+-]?[\d\.]+\s+([+-]?[\d\.]+)/ ); 
    }
    if ( /^IAR / ) {
       print "$_\n" if ($debug); 
       if ( $_ =~  /^IAR\s+\S+\s+([\d\.]+)%/ ) {
          ( $sumdata{iar} ) = ( $_ =~  /^IAR\s+\S+\s+([\d\.]+)%/ ); 
       } elsif ( $_ =~  /^IAR\s+([\d\.]+)%/ ) {
          ( $sumdata{iar} ) = ( $_ =~  /^IAR\s+([\d\.]+)%/ ); 
       } else {
          $sumdata{iar} = 0; 
       }
    }
  }
  if ( eof(SUMFILE) ) {
     return "$sumfile is not a NRCAN summary file, ignore...";
  }

  # Extact product type
  if ( $sumdata{prod} =~ /^...\d\d\d\d\d\.sp3/ ) {
	  ( $sumdata{prod} ) = ( $sumdata{prod} =~ /^(...)\d\d\d\d\d\.sp3/ );
  } elsif ( $sumdata{prod} =~ /^.*_\d*_/ ) {
	  ( $sumdata{prod} ) = ( $sumdata{prod} =~ /^.*(...)_\d*_/ );
  }  
 
  # Read section with coordinate estimates

  # my @tmp;
  my ($sX,$sY,$sZ,$cXY,$cXZ,$cYZ)=(0,0,0,0,0,0);
  my ($sN,$sE,$sU,$cNE,$cNU,$cEU)=(0,0,0,0,0,0);
  my $syst;
  while (<SUMFILE>) {
    chomp($_);
    last if !( /^POS / );
    print "$_\n" if ($debug); 
    @tmp=split(" ",$_);
    print "$tmp[5]\n" if ($debug); 
    if ( /^POS\s+X/ ) {
       print "$_\n" if ($debug); 
	   $syst=$tmp[2];
       $sumdata{X} = $tmp[5];
       $sX = $tmp[7];
    }
    if ( /^POS\s+Y/ ) {
       print "$_\n" if ($debug); 
	   $syst=$tmp[2];
       $sumdata{Y} = $tmp[5];
       $sY = $tmp[7];
       $cXY = $tmp[8];
    }
    if ( /^POS\s+Z/ ) {
       print "$_\n" if ($debug); 
	   $syst=$tmp[2];
       $sumdata{Z} = $tmp[5];
       $sZ = $tmp[7];
       $cXZ =  $tmp[8];
       $cYZ = $tmp[9];
    }
    if ( /^POS LAT/ ) {
       print "$_\n" if ($debug); 
       $sumdata{Lat} = join(" ",$tmp[7],$tmp[8],$tmp[9]);
       $sN = $tmp[11];
    }
    if ( /^POS LON/ ) {
       print "$_\n" if ($debug); 
       $sumdata{Lon} = join(" ",$tmp[7],$tmp[8],$tmp[9]);
       $sE = $tmp[11];
       $cNE = $tmp[12];
    }
    if ( /^POS HGT/ ) {
       print "$_\n" if ($debug); 
       $sumdata{H} = $tmp[5];
       $sU = $tmp[7];
       $cNU =  $tmp[8];
       $cEU = $tmp[9];
    }
  }
  $sumdata{covXYZ} = join(",",$sX,$sY,$sZ,$cXY,$cXZ,$cYZ) ;  
  $sumdata{covNEU} = join(",",$sN,$sE,$sU,$cNE,$cNU,$cEU) ;  
  $sumdata{syst}=$syst;

  # Read summary on satellite information
  # FLG Additional information on each satellite
  #    PRN Satellite PRN
  #    EPO Number of epochs where the satellite is used in the PPP solution
  #    TRK Number of epochs where the satellite is rejected due to missing observations (tracking issues)
  #    CLK Number of epochs where the satellite is rejected due to missing satellite clock corrections
  #    EPH Number of epochs where the satellite is rejected due to missing ephemeris (orbit) corrections
  #    ELV Number of epochs where the satellite is rejected due to elevation angle below cutoff angle
  #    YAW Number of epochs where the satellite is rejected due to satellite yaw manoeuver (eclipse)
  #    DCB Number of epochs where an observation is rejected due to missing DCB corrections
  #    SLP Number of cycle slips detected
  #    MIS Number of epochs where an observation is rejected due to blunders detected in the misclosure vector
  #    RES Number of epochs where an observation is rejected due to a large residual

   $sumdata{numobs}=0;     # EPO
   $sumdata{notrk}=0;      # TRK
   $sumdata{rejected}=0;   # MIS , RES
  
   while (<SUMFILE>) {
    chomp($_);
    if ( /^FLG .XX / ) {
       print "$_\n" if ($debug); 
       @tmp=split(" ",$_);
       $sumdata{numobs}=$sumdata{numobs}+$tmp[2]; 
       $sumdata{notrk}=$sumdata{notrk}+$tmp[3]; 
       $sumdata{rejected}=$sumdata{rejected}+$tmp[10]+$tmp[11]; 
    }
  }
  
  close (SUMFILE);

  if ($debug) {
    foreach $key (sort(keys(%sumdata))) {
      print "$key : $sumdata{$key}\n"
    }
  }
  
  $sumtxt="$sumdata{marker},$sumdata{rnxfile},$sumdata{Lat},$sumdata{Lon},$sumdata{H},$sumdata{covNEU},$sumdata{X},$sumdata{Y},$sumdata{Z},$sumdata{covXYZ},$sumdata{rnxstart},$sumdata{rnxend},$sumdata{rnxinterval},$sumdata{antheight},$sumdata{antenna},$sumdata{receiver},$sumdata{syst},$sumdata{prod},$sumdata{iar},$sumdata{numepochs},$sumdata{numobs},$sumdata{notrk},$sumdata{rejected},$sumdata{ver}";


  #return $sumtxt,%sumdata;
  return $sumtxt;

}

sub ScanLegacySumFile{

  # Scan NRCAN Summary file

  my($sumfile) = @_;
  my($sumtxt)="";
  my(%sumdata);

  my(@fields);

  open(SUMFILE,"$sumfile") ||  die ("Error opening $sumfile\n");


  # Scan preamble
  while (<SUMFILE>) {
    chomp($_);
    last if ( /SECTION 1. File Summary/ );
  }
  if ( eof(SUMFILE) ) {
     return "$sumfile is not a NRCAN summary file, ignore...";
  }

  # Scan SECTION 1
  while (<SUMFILE>) {
    chomp($_);
    last if ( /SECTION 2. Summary of processing parameters/ );
    if ( /Observations/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxfile} ) = ( $_ =~ /Observations\s+(\S+)/ ); 
    }
  }

  # Scan SECTION 2
  while (<SUMFILE>) {
    chomp($_);
    last if ( /SECTION 3. Session Processing Summary/ );
    
  }

  # Scan SECTION 3 until "3.3 Coordinate estimates"
  while (<SUMFILE>) {
    chomp($_);
    # Marker->ARP distance      (m):        1.100 
    last if ( /3.3 Coordinate estimates/ );
    if ( /Marker->ARP distance/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{antheight} ) = ( $_ =~  /([\d\.]+)/ ); 
    }
    # Marker name                       :   KMDA                                 
    # Start                             :   2017/07/04 00:00:00.00               
    # End                               :   2017/07/04 23:59:45.00               
    # Observation interval        (sec) :   15.00                      
    if ( /Marker name/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{marker} ) = ( $_ =~ /Marker name\s+:\s+(\S+)/ ); 
    }
    if ( /Start/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxstart} ) = ( $_ =~ /Start\s+:\s+(\S+\s\S+)/ ); 
    }
    if ( /End/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxend} ) = ( $_ =~ /End\s+:\s+(\S+\s\S+)/ ); 
    }
    if ( /Observation interval/ ) {
       print "$_\n" if ($debug); 
       ( $sumdata{rnxinterval} ) = ( $_ =~ /Observation interval\s+\S+\s+:\s+([\d\.]+)/ ); 
    }
  }
  
  # Read section 3.3 Coordinate estimates

  my @tmp=();
  while (<SUMFILE>) {
    chomp($_);
    last if ( /3.4 Coordinate differences/ );
    push (@tmp,$_);
    #print "$_\n"; 
  }

  ( $sumdata{X} ) = ( $tmp[1] =~ /X \(m\)\s+[\+\-\d\.]+\s+([\+\-\d\.]+)/ );  
  ( $sumdata{Y} ) = ( $tmp[2] =~ /Y \(m\)\s+[\+\-\d\.]+\s+([\+\-\d\.]+)/ );  
  ( $sumdata{Z} ) = ( $tmp[3] =~ /Z \(m\)\s+[\+\-\d\.]+\s+([\+\-\d\.]+)/ );  

  ( $sX , $cXY , $cXZ ) = ( $tmp[7] =~ /X\(m\)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)/ );
  (       $sY  , $cYZ ) = ( $tmp[8] =~ /Y\(m\)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)/ );
  (              $sZ  ) = ( $tmp[9] =~ /Z\(m\)\s+([\+\-\d\.]+)/ );
  
  $sumdata{covXYZ} = "$sX,$sY,$sZ,$cXY,$cXZ,$cYZ" ;  
  
  ( $sumdata{Lat} ) =  ( $tmp[12] =~ /Latitude  \(dms\)\s+[\+\-\d]+\s\d+\s[\d\.]+\s+([\+\-\d]+\s\d+\s[\d\.]+)/ ) ;  
  ( $sumdata{Lon} ) = ( $tmp[13] =~ /Longitude \(dms\)\s+[\+\-\d]+\s\d+\s[\d\.]+\s+([\+\-\d]+\s\d+\s[\d\.]+)/ );  
  ( $sumdata{H} ) = ( $tmp[14] =~ /Elevation \(m\)\s+[\+\-\d\.]+\s+([\+\-\d\.]+)/ );  

  ( $sN , $cNE , $cNU ) = ( $tmp[22] =~ /Lat\(m\)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)/ );
  (       $sE  , $cEU ) = ( $tmp[23] =~ /Lon\(m\)\s+([\+\-\d\.]+)\s+([\+\-\d\.]+)/ );
  (              $sU  ) = ( $tmp[24] =~ /H\(m\)\s+([\+\-\d\.]+)/ );

  $sumdata{covNEU} = "$sN,$sE,$sU,$cNE,$cNU,$cEU" ;  
  
  close (SUMFILE);

  if ($debug) {
    foreach $key (sort(keys(%sumdata))) {
      print "$key : $sumdata{$key}\n"
    }
  }
  
  $sumtxt="$sumdata{marker},$sumdata{rnxfile},$sumdata{Lat},$sumdata{Lon},$sumdata{H},$sumdata{covNEU},$sumdata{X},$sumdata{Y},$sumdata{Z},$sumdata{covXYZ},$sumdata{rnxstart},$sumdata{rnxend},$sumdata{rnxinterval},$sumdata{antheight}";

  #return $sumtxt,%sumdata;
  return $sumtxt;

}

# End of file is here 


