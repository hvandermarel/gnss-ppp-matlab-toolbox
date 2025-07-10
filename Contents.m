% PPP NRCAN Toolbox
% Version 1.2 (31 May 2024)
%
% Main functions:
%
% xtrNRCAN        - Read NRCAN summary files and extract (static position) PPP data.
% pppcombine      - Combine single(-day) PPP solutions into a single multi-day estimate.
% nrcanReadPos    - Read NRCAN position file (kinematic position, clock, ZTD).
%
% Pretty print:
%
% prtNRCAN        - Pretty print results from xtrNRCAN
% prtcombine      - Pretty print results from pppcombine
%
% Demo scripts:
%
% pppdemo1        - Basic demo with xtrNRCAN and pppcombine for static solutions.
% pppdemo2        - Advanced demo processing one year of Iceland PPP data.
% nrcanTopoPoints - Compute Topo Points from NRCAN Kinematic PPP results.
%
% Dependencies: 
%
% crsutil         - Coordinate and reference system toolbox
%
% (c) Hans van der Marel, Delft University of Technology, 2018-2024.
