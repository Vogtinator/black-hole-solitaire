#!/usr/bin/env perl6
#
# fuzz-build.p6
# Copyright (C) 2018 Shlomi Fish <shlomif@cpan.org>
#
# Distributed under terms of the MIT license.
#

sub MAIN(Bool :$g=False, Bool :$t=False, Bool :$rb=False)
{
    my $seed;
    if ($g)
    {
        %*ENV{"FCS_GCC"}=1;
        $seed = $rb ?? 1 !! 1;
    }
    else
    {
        %*ENV{"CC"}=run('which', 'clang', :out).out.slurp.chomp;
        %*ENV{"CXX"}=run('which', 'clang++', :out).out.slurp.chomp;
        %*ENV{"FCS_CLANG"}=1;
        $seed = $rb ?? 1 !! 1;
    }
    %*ENV{"HARNESS_BREAK"}="1";
    my $SLIGHTLY-WRONG-GCC-FLAG-SEE-man-gcc = "-frandom-seed=24";
    %*ENV{"CFLAGS"}="-Werror" ~ (($g && $rb) ?? " $SLIGHTLY-WRONG-GCC-FLAG-SEE-man-gcc"  !! "");
    %*ENV{"SOURCE_DATE_EPOCH"}="0";
    my $cmd ="../scripts/Tatzer && make -j5";
    $cmd ~= " && perl ../source/run-tests.pl" if $t;
    if $rb
    {
        %*ENV{"REPRODUCIBLE_BUILDS"}="1";
        $cmd = Q:qq (bash -c ". ~/.bashrc && Theme fcs && _reprb_diff_builds");
    }
    while True
    {
        say "Checking seed=$seed";
        %*ENV{"FCS_THEME_RAND"}="$seed";
        if shell($cmd)
        {
            ++$seed;
        }
        else
        {
            say "seed=$seed failed";
            last;
        }
    }
}
