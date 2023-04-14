* Possibility to not have spaces at the end of strings?
  (Nice to have; not that important)

* Possibiltiy to reset the loader/parser from error state or from success
  state back to idle by writing to the CSR. Test case:
  Load ThisIsNoCrt, see error message, load Alienator, press reset,
  start alienator, load ThisIsNoCrt and see that there is no error message

* Parsing "hangs" in case of REU mode. Works fine in HW mode and in SW mode.

