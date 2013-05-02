use strict;

use BSD::Resource;

setrlimit('RLIMIT_CPU', 25, 30);
setrlimit('RLIMIT_VMEM', 512*1024*1024, 512*1024*1024);
setrlimit('RLIMIT_NPROC', 100, 100);

$SIG{"XCPU"} = sub {
    die "$0: CPU limit exceeded\n";
};

1;
