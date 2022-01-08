# ProbabilityDensityIntegrator

This is just one implementation of a more flexible pipleine--I'll try to update and add more as the other versions get debugged.

Sorry--it's not overly efficient...I'm sure a real computer scientist can make something much faster that doesn't require a bunch of parfor loops...

Feel free to email me if you need help (obarac@janelia.hhmi.org). It requires the parallel computing package in this form, and it will go easiest if you use the HydraImageProcessor (ericwait/hydra-image-processor) to implement everything.

The basic idea is to run the file prep packages (Part 0 and Part 1) to set things up. Then Part 2 is the major component that takes forever and will convert your data to a polar (in this example) probability distribution. Part 3 just extracts mean values, it should be quite quick (but it is Matlab version dependent, sorry...you may have to update if it doesn't work). Part 4 is an independent, stand alone code that calculates fluorescence asymmetry as was done in the following paper:  https://www.nature.com/articles/s41586-021-04204-9 (PMID 34912111).

If you have trouble send me an email and I'll try to help you get it set up.

Cheers!

Chris O

PS - I added a license file, but basically just feel free to use whatever you need.
