#!/usr/bin/env bash
#   Use this script to test if a given API endpoint returns 200

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname endpoint [-s] [-t timeout] [-- command args]
    -e ENDPOINT | --endpoint=ENDPOINT       API endpoint under test
    -s | --strict                           Only execute subcommand if the test succeeds
    -q | --quiet                            Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT          Timeout in seconds, zero for no timeout
    -- COMMAND ARGS                         Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $ENDPOINT"
    else
        echoerr "$cmdname: waiting for $ENDPOINT without a timeout"
    fi
    start_ts=$(date +%s)
    while :
    do
        echo "Calling $ENDPOINT"
        curl -f $ENDPOINT
        result=$?
        if [[ $result -eq 0 ]]; then
            end_ts=$(date +%s)
            echoerr "$cmdname: $ENDPOINT is available after $((end_ts - start_ts)) seconds"
            break
        fi
        sleep 5
    done
    return $result
}

wait_for_wrapper()
{
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [[ $QUIET -eq 1 ]]; then
        timeout $TIMEOUT $0 --quiet --child $ENDPOINT --timeout=$TIMEOUT &
    else
        timeout $TIMEOUT $0 --child $ENDPOINT --timeout=$TIMEOUT &
    fi
    PID=$!
    trap "kill -INT -$PID" INT
    wait $PID
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for $ENDPOINT"
    fi
    return $RESULT
}

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        http://*:* )
        ENDPOINT=$1
        shift 1
        ;;
        --child)
        CHILD=1
        shift 1
        ;;
        -q | --quiet)
        QUIET=1
        shift 1
        ;;
        -s | --strict)
        STRICT=1
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if [[ $TIMEOUT == "" ]]; then break; fi
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        CLI="$@"
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "$ENDPOINT" == "" ]]; then
    echoerr "Error: you need to provide a valid endpoint to test."
    usage
fi

TIMEOUT=${TIMEOUT:-240}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

# check to see if timeout is from busybox?
# check to see if timeout is from busybox?
TIMEOUT_PATH=$(realpath $(which timeout))
if [[ $TIMEOUT_PATH =~ "busybox" ]]; then
        ISBUSY=1
        BUSYTIMEFLAG="-t"
else
        ISBUSY=0
        BUSYTIMEFLAG=""
fi

if [[ $CHILD -gt 0 ]]; then
    wait_for
    RESULT=$?
    exit $RESULT
else
    if [[ $TIMEOUT -gt 0 ]]; then
        wait_for_wrapper
        RESULT=$?
    else
        wait_for
        RESULT=$?
    fi
fi

if [[ $CLI != "" ]]; then
    if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec $CLI
else
    exit $RESULT
fi
