# Contributions from the 3BAtwin training school

Beamformers written by two teams at the 3BAtwin training school and committed on 3 November 2026 (commit `5ef209d`). The files are kept here as submitted. They have not been reviewed for inclusion in MERIT-EXT or MERIT, they have no reference pages and they are not covered by the tests. [Extending MERIT and MERIT-EXT](../../doc/extending.md) describes how a method is proposed for inclusion, and [TODO](../../TODO.md) gives the skeletons for CF-DAS, corrected DMAS and CR-DAS.

## Use

Each folder is a package with the same interface as MERIT's beamformers: the function returns a handle that `merit.beamform` calls with the delayed signals. Add this folder to the path and call the functions with their package name:

```matlab
addpath('contributions/3batwin-training-school');
img = merit.beamform(signals, frequencies, points, delays, beamformers_team2.team2_GammaDAS(2));
```

## Status of the files

| File | Method | Status |
| --- | --- | --- |
| `+beamformer_team1/team1_CFDAS.m` | Delay-and-sum weighted by the coherence factor (Klemm et al., 2009) | The coherence factor is divided by the number of channels, as in the paper. The values are squared without `abs`, so the result is correct only for real (time-domain) signals. |
| `+beamformer_team1/team1_CRDAS.m` | Channel-ranked delay-and-sum (O'Halloran et al., 2010) | Does not implement the method. The channels are ranked by signal amplitude along the points dimension, not by propagation distance to each point, and the sort permutation is used as the rank. |
| `+beamformers_team2/team2_CFDAS.m` | Delay-and-sum weighted by the coherence factor | Does not run. The body uses `delayed_signals` while the input is named `delayed`, and the function still ends with the "not implemented" error from the skeleton. Its `arguments` block is not supported by the MATLAB release on which MERIT-EXT is tested. |
| `+beamformers_team2/team2_GammaDAS.m` | Delay-and-sum followed by a power-law (gamma) transformation | Raises the delay-and-sum image to the power `gamma` (default 2). Not yet tested. |
| `+beamformers_team2/team2_IDMAS.m` | Iterative delay-multiply-and-sum | One iteration forms every pair of different channels once, through suffix sums; more iterations give higher-order stages. Not yet tested. |

Both teams also submitted copies of MERIT's `DAS.m`, `CDAS.m` and `DMAS.m`. They were identical to MERIT's functions apart from comments and were removed; MERIT's own functions are used instead.
