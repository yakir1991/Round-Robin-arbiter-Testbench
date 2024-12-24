#!/bin/csh -f

cd /users/pd13/arbiter_2/arbiter

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/eda/synopsys/2021-22/RHELx86/VCS_2021.09-SP1/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \
    +vcs+lic+wait \

cd -

