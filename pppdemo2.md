
# PPPDEMO2 and PPPDEMO2XL example scripts

In the `pppdemo1.m` script an example is given how to read multiple days of data from NRCan CSRS-PPP summary files, combine then into a single multi-day solution with statistical testing, and how to exclude some days from the processing. The accompanying document [pppdemo1.md](./pppdemo1.md) explained how to interpret the statistical testing output and results.

The material is further developed in the `pppdemo2.m` and `pppdemo2xl.m` scripts. New features are

* process all stations of a GNSS campaign,
* automatic outlier detection and removal (remove days with omt values exceeding a user defined threshold),
* graphics.

The basics of `pppdemo2.m` and `pppdemo2xl.m` are the same.
The main difference is that `pppdemo2xl` combines the graphics into a single figure, allows to have split campaigns (with a pause between the observations), has a csv file output with the results and has more wissles and bells when it comes to settings and options.

## Program flow

The difference with the previous example in `ppdemo1.m` is that two loops around `xtrNRCAN.m` and `pppcombine.m` are added:

```text
set path to campaign directory
set thresholds for outlier detection
foreach station in campaign directory
    read all NRCan CSRS-PPP for that station (multiple days of data) using xtrNRCAN.m
    combine the single day solutions into one multiday solution with satistical testing using pppcombine.m
    while omt > threshold && numdays > 2
        find the day with largest omt value
        redo the combination without that day
    save the results
print overview of stations and days which had outliers and were removed
print results
create graphics
```

The amount of print output within the loop is kept to a minimum, instead the results are collected,  printed and plotted once the processing has finished.

## Campaign directory settings and data organisation

Few things need to be set at the start of the processing.
The more important ones are the campaign name `campaign`, the path `rootdir` to the campaign directory and the pattern `filepattern` with the CSRS-PPP output files.

```matlab
campaign='2029';
dirroot= '../2019/03_PPP/BLAS/';
filepattern='*.zip';   % '*.zip' or '*.sum'
```

These setting are used to create a structure array `dirnames` with all the folder names.
The file pattern for CSRS-PPP output files is then

```matlab
filespec=fullfile(dirroot,dirnames(k).name,filepattern);
```

Optionally it is possible to define a subset of selected stations by uncommenting and changing the following section of code

```matlab
% select subset which has tp be processed (uncomment next section)
% selectstations={ ...
%     'AUSB' 'BF13' 'FM15' 'HRHA' 'KB11' 'KMDC' 'KROV' 'L595' 'L597' 'L598' ...
%     'L599' 'L603' 'L604' 'L671' 'L684' 'L685' 'LV20' 'MYVN' ...
%     'NAMA' 'RAHO' 'RAND' 'THHY' 'TR32' 'TR34'  'VITI' };
% dirnames( ~ismember({dirnames.name},selectstations) )=[];
```

Like in the previous example we assume that the CSRS-PPP zip files are stored in subdirectories for each station, and that the name of these subdirectories is the 4-letter abbreviation of the station.
The name of the subdirectory takes preference over any names that may be defined inside the CSRS-PPP zip files.

## User defined thresholds

There are two main loops in the software.

The first loop is over the subdirectories with station data. In this loop multiple days of data are combined into one (or more) multiday solutions.
In case of `pppdemo2.m` there is one combined solution for each station, however, in case of `pppdemo2xl` a new multi-day solution may be introduced after a (large) gap in the data. The criterion to start a new multi-day solution, with the number in days, is (only for `pppdemo2xl`):

```matlab
mingap_to_start_new_multiday_solution=3;
```

The second loop is a while loop in which successively days are excluded from the processing until one of the following conditions is met

1. the Overall Model Test (omt) is below an user defined criterion, or
2. the number of days in the processing is less than three.

In `pppdemo2.m`, as long as `multiday_omt > maxomt_for_reprocessing && numdays > 2` test `true`, the day with the largest `daily_omt` is removed from the combination. The settings are

```matlab
maxomt_for_reprocessing=2;
maxomt_for_save=10;
```

Once no more outliers are found, and `multiday_omt < maxomt_for_save`, the combined solution is saved  in a structure array `pppsave`.

For `pppdemo2xl.m` a sligthly different test is used,  if `( multiday_omt > maxomt_for_reprocessing_multi_day || max(daily_omt) > maxomt_for_reprocessing_single_day ) && numdays > 2` test `true`, the day with the largest `daily_omt` is removed from the combination. The settings are

```matlab
maxomt_for_reprocessing_multi_day=2;       % same as max_omt_reprocessing in pppdemo2.m
maxomt_for_reprocessing_single_day=10;
maxomt_for_save=10;
```

You may tweek these settings to improve the results. In general it is a good idea to start a run with large values to address the main outliers first, and then, after correcting them, repeat the exercise with slightly lower values.

Of course, you can also replace the above tests with your own. If you intent to do so, please have a look at [pppdemo1.md](./pppdemo1.md) for possibilities.

## Loop output

During the processing short status messages are printed so that you keep track of the progress.
The output for two stations is shown below:

```text
Processing SAMD ...

Changed station name in samd1740.19o from 47701740 to SAMD
Changed station name in samd1750.19o from 47701750 to SAMD
Changed station name in samd1760.19o from 47701760 to SAMD
Changed station name in samd1770.19o from 47701770 to SAMD

Processing SAMD done (OMT value 0.393)
Observation file       OMT
        samd1740.19o    0.107
        samd1750.19o    0.500
        samd1760.19o    0.647
        samd1770.19o    0.434


Processing SKHO ...

Processing SKHO done (OMT value 5.339)
Observation file       OMT
        skho1760.19o   16.809
        skho1770.19o    0.747
        skho1780.19o    5.585
        skho1790.19o    0.740
        skho1800.19o    0.327


*** Removing solution file skho1760.19o from combination ***

Re-processing SKHO done (OMT value 1.526)
Observation file       OMT
     skho1770.19o    0.943
     skho1780.19o    3.609
     skho1790.19o    0.979
     skho1800.19o    0.705
```

For the first station, SAMD, no problems are detected except for a misalignment in the station name.
In case of the second station the *multiday-omt* is rejected in the first iteration, leading to the removal of the first day of data.
After the second iteration the *multiday-omt* is accepted, though the *daily-omt* of day *178* is still on the large side, but below the criterion we set.

The output for just two stations is shown. When processing a lot of stations the output becomes a bit terse, but don't worry, the graphics will provide you with a much more compact and even more powerful picture.

## Summary of removed data files

Once all stations have been processed, a summary is printed of the data files that have been removed with their *omt* at the time of removal.

```text
Files removed from the combination (15):

Name  Obsfile             OMT
HITR  hitr1760.19o        4.42
L102  l1021770.19o       3.233
L157  l1571780.19o       4.344
L671  l6711770.19o       2.286
LV20  lv201760.19o       5.057
SKHO  skho1760.19o       16.81
SKIL  skil1760.19o       3.789
TR10  tr101760.19o       11.52
TR15  tr151780.19o   4.737e+10
TR22  tr221771.19o   8.379e+12
TR22  tr221780.19o       4.189
TR37  tr371750.19o   9.372e+09
TRG1  trg11760.19o       11.72
VIDA  vida1780.19o       8.802
VIDA  vida1760.19o       6.724

No stations are skipped (because of errors)
```

In case there have been unresolved errors (none in our example), this information is also printed.

As you can observe there are a few observation files with very large *omt*.
You could ignore these, and just go on, but the is SELDOMLY a good idea!
At the very least you should inspect the offending files, and if possible correct the underlying problems.
It may be a wrong antenna height, it may be a mistake in data editing where some of the data from a previous station occupation is still in (the probable cause for the very large OMT values), wrong antenna type, etc.
Only when you cannot identify the cause, or have good reason not to use the data, the observation file may be left out.

## csv files

For the station that passed the `maxomt_for_save` criterion the results are written to a csv file.

In our example, the first five lines of the csv file are:

```text
site,dyear,latitude,longitude,height,sN,sE,sU,cNE,cNU,cEU,wrmsN,wrmsE,wrmsU,omt,omt2d,omt1d,antheight
1008,2019.472, 65.6198852453,-17.5097214543, 219.7818,  0.5, 0.7, 1.6,  0.03, 0.03,-0.03,  0.2, 0.7, 2.1,  0.2, 0.1, 0.7, 1.0970
AMTM,2019.472, 65.6593562562,-16.5684827313, 443.0909,  1.5, 1.9, 4.7, -0.20, 0.07, 0.15,  0.4, 1.4, 3.1,  0.3, 0.3, 0.6, 1.1800
AUSB,2019.472, 65.7141171829,-16.5363157753, 478.4879,  0.8, 1.1, 2.4, -0.14,-0.10, 0.09,  1.2, 1.3, 1.2,  0.9, 1.3, 0.4, 0.9460
AUSH,2019.477, 65.6439796135,-16.6700960540, 432.0017,  1.4, 1.8, 4.3, -0.23,-0.16, 0.19,  1.3, 0.5, 2.1,  0.2, 0.2, 0.4, 1.1700
...
```

with the name, epoch, latitude and longitude in degrees, height in meters, formal standard deviation in N, E and U in mm, the correlations, weighted rms in mm, various omt values, and antenna height for each station.

A shortened version of the csv file (everything, except the correlations), is printed to the Matlab console.

## Graphics

An example of the `pppdemo2xl.m` graphics output is shown below.

![pppdemo2xl.m graphics](PPP_Station_Quality_2019.png)

The first two subplots on the left gives the 3D single-day and multi-day omt values for each station.
The 3D single-day omt values in the first plot are represented by a square, whereby the size and color depends on the actual value given by the colorbar.
For the observation files that were removed during testing a cross is printed.

The third and fourth subplot give the 2D and 1D omt values, with single-day values plotted as symbols in the third subplot and the multi-day values as bar chart in the fourth subplot.
The 2D single-day omt values for the horizonal position are depicted by a triangle, and the 1D values for the height by a circle.
The size and color of the symbols is a function of the omt values, as given in the colorbar.  
It a day for a specific station is excluded from the processing this is represented by a cross.

The three subplots on the right are bar charts giving for each of the coordinates (latitude, longitude, height) respectively the formal errors from the co-variance matrix, the weighted RMS value and the omt value for each coordinate.

The expected values for the *overall model test (omt)*  is one; *omt* values much larger than one are an indication of problems with the data.
For a more detailed description of each of these quantities we refer to the description given in [pppdemo1.md](./pppdemo1.md).

The ouput from `pppdemo2.m` is more or less the same, but split into three separate plots.
In `pppdemo2.m` also a fourth plot is added with the *rms* values instead of the *wrms* values.
