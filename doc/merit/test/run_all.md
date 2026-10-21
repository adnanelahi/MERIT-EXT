# merit.test.run_all

Run the unit tests in the package `merit.test.from_list`

Package: `merit.test`

## Syntax

```text
[results, suite] = merit.test.run_all()
```

## Description

`[results, suite] = merit.test.run_all()` collects the class-based unit tests in `merit.test.from_list` and its subpackages, runs them and returns the results. The tests cover beamforming, the imaging domain, the chirp-z transforms, delays, remapping, resampling and channel indexing, and compare MERIT's delay-and-sum images of the UM-BMID dataset with those of the ORR-EPM software.

## Examples

### Run the tests and count the results

```matlab
[results, suite] = merit.test.run_all();
fprintf('%d tests, %d passed, %d failed\n', numel(results), sum([results.Passed]), sum([results.Failed]));
```

## Output Arguments

### `results` — test results

array of `matlab.unittest.TestResult`

### `suite` — test suite

array of `matlab.unittest.Test`

## Tips

- The amplitude tests of `merit.test.from_list.process.test_czt` call `crosscorr`, a function of the Econometrics Toolbox; without that toolbox they stop with an error.
- The test `merit.test.from_list.um_bmid.test_ummid_render` needs the UM-BMID dataset in `../um_bmid/datasets/` and images produced by the ORR-EPM script `reconstruct_imgs.py` in `../orr_epm/output/`, both relative to the current folder. The comments in the test and the shell script in its `private` folder describe how to prepare them. Without these files the test fails.
- The function was called `merit.run_tests` before version 1.0, and the tests were in the package `merit.tests`.

## See Also

[merit.test.time_this](time_this.md) | [merit.test.profile_this](profile_this.md)
