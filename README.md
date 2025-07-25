# GNSS Precise Point Positioning (PPP) Matlab Toolbox

Version 1.3 (15 July 2025)

## Synopsis

Functions and example script to read data from NRCan CSRS-PPP output files and combine the single day
solutions into a single multi-day solution with statistical testing.
Applications range from computing multiday station coordinates, with statistical testing, up to quality
control for a multi-week GNSS campaign with automatic outlier detection and powerful graphics.

![pppdemo2xl.m graphics](PPP_Station_Quality_2019.png)

## Functions

Main functions:

    xtrNRCAN        - Read NRCan CSRS-PPP summary files and extract (static position) PPP data.
    pppcombine      - Combine single(-day) PPP solutions into a single multi-day estimate.
    nrcanReadPos    - Read NRCan CSRS-PPP position file (kinematic position, clock, ZTD).

Pretty print:

    prtNRCAN        - Pretty print results from xtrNRCAN
    prtcombine      - Pretty print results from pppcombine

## Demo scripts and documentation

Several demonstration scripts are provided

    pppdemo1        - Basic demo reading CSRS-PPP output files and a single multi-day combined solution
    pppdemo2        - Advanced demo processing one year of Iceland PPP data.
    pppdemo2xl      - Idem, but with a few more options.
    nrcanTopoPoints - Compute Topo Points from CSRS-PPP kinematic PPP results.

A full description for the first three scripts is given in [pppdemo1.md](./pppdemo1.md) and [pppdemo2.md](./pppdemo2.md),
including a brief description of the statistical testing in [pppdemo1.md](./pppdemo1.md).

## Dependencies

The demo scripts use several functions from the **crsutil-matlab-toolbox** which must be included in the Matlab search path.

## License notice

The following notice applies to all Matlab functions and scripts in this repository.

Copyright 2018-2025 Hans van der Marel, Delft University of Technology.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0).
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
