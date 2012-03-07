require 'mkmf'

$warnflags.gsub! /-Wdeclaration-after-statement/, '' if $warnflags
$CFLAGS << " -std=c99"

create_makefile 'knowledge'