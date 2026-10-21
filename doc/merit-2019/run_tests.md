# merit.run_tests

Run the unit tests in the package `merit.tests`

Package: `merit`

## Syntax

```text
[results, suite] = merit.run_tests()
```

## Description

`[results, suite] = merit.run_tests()` collects the class-based unit tests in `merit.tests` and its subpackages, runs them and returns the results. The tests cover beamforming, the imaging domain, the chirp-z transforms, delays, remapping, resampling and channel indexing.

## Examples

### Run the tests and count the results

```matlab
[results, suite] = merit.run_tests();
fprintf('%d tests, %d passed, %d failed\n', numel(results), sum([results.Passed]), sum([results.Failed]));
```

On MATLAB R2018a with the Signal Processing Toolbox, 79 of the 97 tests pass. The other 18, the amplitude tests of `merit.tests.process.test_czt`, stop with an error because they call `crosscorr`, a function of the Econometrics Toolbox.

## Output Arguments

### `results` — test results

array of `matlab.unittest.TestResult`

### `suite` — test suite

array of `matlab.unittest.Test`

## Tips

- The run prints a progress report and a summary of the failures. `table(results)` shows the results as a table.

## See Also

[matlab.unittest.TestSuite](https://www.mathworks.com/help/matlab/ref/matlab.unittest.testsuite-class.html)
