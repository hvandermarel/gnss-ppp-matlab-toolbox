
# PPPDEMO1 example script

Demo script to read data from NRCan CSRS-PPP summary files and combine the single day solutions into a single multi-day solution with statistical testing.

This is the same example that is given in the help of the `pppcombine` function.

## Contents

* [Read NRCAN CSRS-PPP solution files and extract the relevant information](#read-nrcan-csrs-ppp-summary-files-and-extract-the-relevant-information)
* [Combine single day solutions into one multi-day solution with statistical testing](#combine-single-day-solutions-into-one-multi-day-solution-with-statistical-testing)
* [Repeat the combination, but without the last day (which has a high OMT value)](#repeat-the-combination-but-without-the-last-day-which-has-a-high-omt-value)

## Read NRCan CSRS-PPP summary files and extract the relevant information</a>

The function `xtrNRCAN` is used to read the contents of one or more CSRS-PPP summary files and extract the relevant information into a Matlab structure `pppstruct`.
The function is able to read the summary file directly from the zip file provided by the CSRS-PPP service.
Internally a Perl script is used to parse the summary file.

In general `xtrNRCAN` doesn't care about the contents. It can be used to read the data for a single file, single station or all stations in a multi-station multi-day GNSS campaign. However, for the purpose of combining multiple days of data from the same station, we assume that the CSRS-PPP zip files are stored in a folder structure with a subdirectory per station.

The following code example is going to combine 4 days of data from a station called `BLAS`.  We assume that the four zip files from CSRS-PPP are stored in the subdirectory `../2019/03_PPP/BLAS/`.
The code first sets the path to the zip files, then reads the summary files contained within each of the four zip files and prints a summary using the function `prtNRCAN`.  

```matlab
filespec = '../2019/03_PPP/BLAS/*.zip';  
pppstruct = xtrNRCAN(filespec);
prtNRCAN(pppstruct)
```

The output is

```
name                     first                 last  receiver type         antenna type           anthgt    %epo   %used    %obs    %iar  nsat  #rej  prod
---------  -------------------  -------------------  --------------------  --------------------  -------  ------  ------  ------  ------  ----  ----  ----
30321730   2019-06-22 13:19:00  2019-06-22 23:59:45  TRIMBLE 5700          TRM57971.00     NONE   1.1810  100.0%  100.0%  100.0%    0.0%  10.5     0   igs  
30321740   2019-06-23 00:00:00  2019-06-23 23:59:45  TRIMBLE 5700          TRM57971.00     NONE   1.1810  100.0%  100.0%   99.9%    0.0%  10.0     0   igs  
30321750   2019-06-24 00:00:00  2019-06-24 23:59:45  TRIMBLE 5700          TRM57971.00     NONE   1.1810  100.0%  100.0%   99.9%    0.0%  10.0     0   igs  
30321760   2019-06-25 00:00:00  2019-06-25 15:37:45  TRIMBLE 5700          TRM57971.00     NONE   1.1810  100.0%  100.0%   99.9%    0.0%   9.9     0   igs  
```

The printed summary shows only a subset of the data that is stored in the Matlab structure `pppstruct`. This structure is a flat structure (not a structure array): the fields are mostly arrays with the data for the different days.

Each day of data has its own position solution.

## Combine single day solutions into one multi-day solution with statistical testing

To combine the daily solutions into a single multi-day solution the function `pppcomb` is used. The following code snippet does the combination and prints the most relevant results.

```matlab
pppcomb=pppcombine(pppstruct);
prtcombine(pppcomb)
```

The output is

```
Message PPPCOMBINE: Station names in name field do not match, get name from first 4 characters of filename instead.

Station name:           blas
Observation period:     2019-06-22 13:19:00 - 2019-06-25 15:37:45
Observation interval:   15.0 [s]
Antenna height:         1.1810 [m]

Coordinates (IGS14):
  Mean epoch:           24-Jun-2019 02:28:22   (2019.476)
  Cartesian \[m\]:        2493197.9643  -756391.0774  5802569.2711
  Geodetic \[deg/m\]:     65.9629321895  -16.8768464833   332.9862
  Geodetic \[dms/m\]:     65 57 46.5559  -16 52 36.6473   332.9862

Coordinate uncertainties:
                         st.dev. in [mm]             Correlations
  method
                      North    East      Up        N-E    N-U    E-U
                     ------  ------  ------     ------ ------ ------
  cov-matrix           0.90    1.23    2.55      -0.01  -0.04   0.01
  emperical (rms)      1.02    1.81    1.79
  emperical (wrms)     0.78    1.32    1.52

                          X       Y       Z        X-Y    X-Z    Y-Z
                     ------  ------  ------     ------ ------ ------
  cov-matrix           1.34    1.23    2.34      -0.04   0.66  -0.20
  emperical (rms)      0.52    1.81    1.99
  emperical (wrms)     0.49    1.32    1.65

Overall Model Test (omt):  1.074   (2D: 1.336, 1D: 0.490)

obsfile                                     res-N   res-E   res-U    wtst-N wtst-E wtst-U    omt-2D omt-1D  omt-3D  
--------------------------------------    ------- ------- -------    ------ ------ ------    ------ ------  ------  
blas1730.19o                                  0.2     3.6     0.4      0.09   1.08   0.07     0.622  0.005   0.406 
blas1740.19o                                  0.0     0.4     3.3      0.04   0.21   0.91     0.023  0.835   0.294 
blas1750.19o                                  1.4     1.5     0.4      1.10   0.86   0.12     0.990  0.014   0.665 
blas1760.19o                                 -3.3    -4.9    -5.2     -1.70  -2.11  -1.07     3.488  1.137   2.814 
                                          ------- ------- -------    ------ ------ ------    ------ ------  ------  
rms, omt                                     2.04    3.62    3.58     1.035  1.295  0.700     1.336  0.490   1.074 
wrms                                         1.55    2.63    3.04
```

Note that `pppcombine` complains that the first four characters from the filename do not match with the station names in the summary files (which is taken from the RINEX file that was uploaded to the CSRS-PPP service). The first four characters of the filename take preference over the station name in the summary files, as the latter not always set properly in the RINEX files.

The output of `prtcombine` consists of four blocks:

1. Station name, start and end time, interval and antenna height
2. Station coordinates from the combination in different formats, the reference frame and the mean epoch
3. Precision of the coordinates, in local North, East and Up coordinates, and in geocentrix X, Y and Z coordinates. Three different types of standard deviations are provided:
    * formal standard deviation and correlation computed from the co-variance matrix given by CSRS-PPP (formal errors),
    * emperical standard deviation *(rms)* computed from the residuals (show in the next block),
    * weighted rms *(wrms)* computed from the residuals but weighted by the formal errors.
4. Residuals and results of the statistical testing, with
    * omt summary line giving the results of the Overall Model Test (omt) for the combined solution, in all three dimensions, but also for the horizontal (2D) and vertical (1D) components individually
    * a table with for each observation file,
        * residuals in North, East and Up direction *(res-N, res-E, res-U)*, these are the differences between the daily and combined solutions,
        * w-test statistic for the North, East and Up component *(wtst-N, wtst-E, wtst-U)*. Another name for the w-test statistic is *normalized residual*; the residual divided by the formal standard deviation of the residual (computed by propagating error variances from the individual and combined solution)
        * horizontal (2D), vertical (1D) and 3D Overall Model Test values per observation file *(omt-2D omt-1D omt-3D)*.
    * the bottom two lines of the table show
        * under the residuals, the root mean square error (rms) and weighted rms of the residuals. The rms and wrms values in this block are not the same as the ones reported in the third block. The values in the third block are smaller, as these are for the combined solutions, whereas the values here are for the daily solutions.
        * under the w-test values, the square root of the Overall Model Test (omt) for the North, East and Up component (square root so that it can be compared to the w-test values), and
        * under the omt values, the horizontal, vertical and overall model test values for the whole solution (identical to the ones reported in the omt summary line).

The result of the combination is stored in the Matlab structure `pppcomb`.

The expected values for the *overall model test (omt)* and *w-test* values is one; *omt* and *w-test* values much larger than one are an indication of problems with the data. As a rule of thumb, when the absolute w-test value is larger than `3.29` the corresponding observation is generally considered to be an outlier.
The critical values the *omt* a slighty smaller because of the higher redundancy.
However, because of the small amount of data, and the inaccuracy of the stochastic models, the *omt* and *w-test* values should be considered only as an indication to support a human interpretation of the result. 

To better understand the outcome of the statistical testing a brief explanation ot the *Delft school* statistical testing method is given.

The functional model is $E\{\bf{y}\} = \bf{A}\bf{x}$ with $\bf{y}$ the $m \times 1$ vector of observations, $\bf{x}$ the $n \times 1$ vector of unknown parameters and $\bf{A}$ the so-called $m \times n$ design matrix. For the combination we have:

* $\bf{y}$ the $m \times 1$ vector of observations with CSRS-PPP daily coordinates, with
$\bf{y}^\intercal = [ \bf{y}_1^\intercal \ \bf{y}_2^\intercal \ldots \ \bf{y}_M^\intercal ]$ and $\bf{y}_i$, $i = 1, 2, \ldots M$, vectors with the three coordinates for each daily solution, $M$ the number of days and $m=3*M$
* $\bf{x}$ the $n \times 1$ vector with unknown parameters with the three coordinates of the combined solution ($n=3$)
* $\bf{A}$ the $m \times n$ design matrix, composed of $M$ $3 \times 3$ identity matrices, with  $\bf{A}  = [ \bf{I}_3 \ \bf{I}_3 \ \ldots \ \bf{I}_3 ]^\intercal$

The stochastic model is defined by the $m \times m$ co-variance matrix $\bf{Q}_y$ of the observations.
This matrix is a block diagonal matrix $\bf{Q}_y = \text{diag}( \bf{Q}_{y_1} ,\ \bf{Q}_{y_2} \ldots \ \bf{Q}_{y_M} )$ with $\bf{Q}_{y_i}$ for $i = 1, 2, \ldots M$  the $3 \times 3$ co-variance matrix of the daily coordinates from the CSRS-PPP summary file.

The least-squares estimate $\hat{\bf{x}}$ giving the combined coordinate solutions is
$\hat{\bf{x}}= ( \bf{A}^\intercal \bf{Q}_y^{-1} \bf{A} )^{-1} \bf{A}^\intercal \bf{Q}_y^{-1} \bf{y}$, with
$\bf{Q}_{\hat{x}} = ( \bf{A}^\intercal \bf{Q}_y^{-1} \bf{A} )^{-1}$ the $3 \times 3$ co-variance matrix for the estimated parameters.

The $m \times 1$ vector with least-squares residuals is equal to $\hat{\bf{e}} = \bf{y} - \bf{A}\hat{\bf{x}}$. The co-variance matrix of the least-squares residuals is computed as $\bf{Q}_{\hat{e}} = \bf{Q}_y - \bf{A} \bf{Q}_{\hat{x}} \bf{A}^\intercal$.

The w-test value for the $i$'th observation is equal to $w_i = e_i / \sigma_{e_i}$, with $e_i$ the $i$'th element from $\hat{\bf{e}}$ and $\sigma_{e_i} = \sqrt{{\bf{Q}_{\hat{e}}}_{ii}}$.

The overall model test is

```math
\text{omt}  =  \frac{\bf{e}^\intercal \bf{Q}_y^{-1} \bf{e}}{m-n} \ \ \ \ \ , \ \ \ \ \ \text{for subset} \  S \ \text{:} \ \ \ \text{omt}_S = \frac{\bf{e}_s^\intercal \bf{Q}^{-1}_{y_S} \bf{e}_s}{r_s} \ \ \ \ \ \text{with} \ \ \ \ \  r_s = \sum_S \frac{\sigma_{\hat{e}}^2}{\sigma_y^2}
```

with $r_s$ the redundancy number.
The overall model test can be computed with all observations or for a subset $S$ of observations.
When all observations are used the redundancy $r_s$ is equal to $m-n$.
Using different subsets $S$ of observations allows for testing different components of the solution.
Possible subsets are all observations for a single day, all observations for a single coordinate component (North, East, Up/Vertical, Horizontal), or a combination of the two.

## Repeat the combination, but without the last day (which has a high OMT value)

```
fprintf('Repeat the combination without the last day\\n\\n');

pppcomb=pppcombine(pppstruct,\[ 1 2 3  \]);
prtcombine(pppcomb)
```
```
Repeat the combination without the last day

Message PPPCOMBINE: Station names in name field do not match, get name from first 4 charaters of filename instead.
Station name:           blas
Observation period:     2019-06-22 13:19:00 - 2019-06-24 23:59:45
Observation interval:   15.0 \[s\]
Antenna height:         1.1810 \[m\]

Coordinates (IGS14):
  Mean epoch:           23-Jun-2019 18:39:22   (2019.475)
  Cartesian \[m\]:        2493197.9648  -756391.0761  5802569.2728
  Geodetic \[deg/m\]:     65.9629321952  -16.8768464534   332.9878
  Geodetic \[dms/m\]:     65 57 46.5559  -16 52 36.6472   332.9878

Coordinate uncertainties:
                         st.dev. in \[mm\]             Correlations
  method
                      North    East      Up        N-E    N-U    E-U
                     ------  ------  ------     ------ ------ ------
  cov-matrix           0.99    1.39    2.87      -0.02  -0.04   0.03
  emperical (rms)      0.44    0.96    0.97
  emperical (wrms)     0.38    0.58    0.84

                          X       Y       Z        X-Y    X-Z    Y-Z
                     ------  ------  ------     ------ ------ ------
  cov-matrix           1.51    1.39    2.64      -0.01   0.67  -0.20
  emperical (rms)      0.62    1.01    0.80
  emperical (wrms)     0.56    0.69    0.65

Overall Model Test (omt):  0.219   (2D: 0.263, 1D: 0.125)

obsfile                                     res-N   res-E   res-U    wtst-N wtst-E wtst-U    omt-2D omt-1D  omt-3D  
--------------------------------------    ------- ------- -------    ------ ------ ------    ------ ------  ------  
blas1730.19o                                 -0.5     2.3    -1.1     -0.23   0.69  -0.18     0.267  0.032   0.196 
blas1740.19o                                 -0.6    -1.0     1.8     -0.48  -0.61   0.52     0.303  0.272   0.291 
blas1750.19o                                  0.8     0.2    -1.1      0.64   0.09  -0.33     0.217  0.110   0.178 
                                          ------- ------- -------    ------ ------ ------    ------ ------  ------  
rms, omt                                     0.76    1.66    1.68     0.463  0.559  0.353     0.263  0.125   0.219 
wrms                                         0.66    1.01    1.45
```
  
