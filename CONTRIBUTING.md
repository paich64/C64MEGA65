Contributing to C64MEGA65
==========================

You want to help? Welcome! Highly appreciated :-)

Important: Make sure that you are familiar with the following before starting
to contribute:

* MEGA65
* FPGA development using VHDL or Verilog and the Vivado toolchain
* MiSTer2MEGA framework: https://github.com/sy2002/MiSTer2MEGA65
* QNICE: https://github.com/sy2002/QNICE-FPGA

We do not have a lot of rules, neither do we have a detailed written code of
conduct or even written coding guidelines. As written above: This is meant to
be a relaxed project :-) Nevertheless, here are some basics that we expect you
to follow when contributing.

Style
-----

* Ensure consistency: When editing an existing file, no matter if it is code
  or documentation, please stick as closely as you can to the style of the
  existing file. We sometimes do have mixed programming styles in multiple
  files; but we try to be consistent as possible within one file.
  
* Use American English. That means for example: color instead of colour,
  behavior instead of behaviour, favorite instead of favourite,
  center instead of centre, fiber instead of fibre,
  license instead of licence, etc.

Branches
--------

* The `master` branch is meant to be our stable branch. Usually, the master
  branch is identical to the latest release.

* The `develop` branch is where most of the development happens. It is
  semi-stable that means that we try to avoid to commit breaking changes that
  take longer than a day or so to develop or to fix.

* There are various `dev-*` and `develop-*` branches: Here we are developing
  larger features that take a while and here it might be, that parts of
  the system are broken.

Pull Requests
-------------

* Make Pull Request for the `develop` branch, unless you have a very good
  reason to use another branch.

* Please use GitHub's features to describe your PR thoroughly.

* Make sure that you test your changes thoroughly. It is a best practice
  to share your beta-version of the new core with people on the MEGA65
  Discord (#other-cores channel) or with other beta testers, so that a
  wide range of test cases (and hardware combinations) are tested.

* If you plan a larger contribution, it might make sense to discuss it
  with us upfront by opening an issue: Describe what you plan to do
  and @mention one or more of the core developers.

* Try to stick to the coding style of the actual file(s) that you are
  modifying. The styles might differ per file.

License & Credit
----------------

* If you contribute, make sure that your code is under GPL v3 (see LICENSE).

* We will give you credit in the AUTHORS file.

* It is unlikely that we will mention you in the slpash screen of the core
  or in the publicly visible list of authors (currently MJoergen & sy2002)
  as long as your contributions are not equal to ours.
