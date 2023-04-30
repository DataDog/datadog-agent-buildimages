param ($cmd)

if ( $cmd -eq "test" )
{
    cd C:\mnt\go\src\github.com\DataDog\datadog-apm-inject\
    ridk enable
    inv injection-controller.test
}

if ( $cmd -eq "build" )
{
    cd C:\mnt\go\src\github.com\DataDog\datadog-apm-inject\
    ridk enable
    inv injection-controller.build

}

if ( $cmd -eq "run" )
{
    cd C:\mnt\go\src\github.com\DataDog\datadog-apm-inject\
    Copy-Item ./injection-controller/bin/apm-inject.yaml c:\programdata\datadog\apm-inject.yaml
    ./injection-controller/bin/injectioncontroller
}


