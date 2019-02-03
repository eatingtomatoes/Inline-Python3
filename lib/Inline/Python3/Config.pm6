unit module Config;

use NativeCall;

constant PyRef is export = Pointer;

constant $pyhelper is export = %?RESOURCES<libraries/pyhelper>.Str;

constant $perl6 is export = %?RESOURCES<libraries/perl6>.Str;

multi sub trait_mod:<is>(Routine $r,  :$capi!) is export {
    trait_mod:<is>($r, native => $pyhelper);
    trait_mod:<is>($r, symbol => $capi) if $capi ~~ Str;
}

multi sub trait_mod:<is>(Routine $r, :$pymodule!) is export {
    trait_mod:<is>($r, native => $perl6);    
}
