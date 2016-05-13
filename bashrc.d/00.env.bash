# Get TTY number, last 2 digits
TTY_NUM=$(tty|cut -c11-)

# Prevent tar include "._" file resource forks
export COPYFILE_DISABLE=true
