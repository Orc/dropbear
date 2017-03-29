#! /bin/sh

# local options:  ac_help is the help message that describes them
# and LOCAL_AC_OPTIONS is the script that interprets them.  LOCAL_AC_OPTIONS
# is a script that's processed with eval, so you need to be very careful to
# make certain that what you quote is what you want to quote.

# load in the configuration file
#
TARGET=dropbear
. ./configure.inc

AC_INIT $TARGET

AC_PROG_CC

AC_SUB 'BUNDLED_LIBTOM' '1'
AC_DEFINE 'BUNDLED_LIBTOM' 1
AC_SUB 'EXEEXT' ''
AC_SUB 'CRYPTLIB' ''

AC_DEFINE 'explicit_bzero(x,s)' 'memset(x, 0, s)'

AC_LIBRARY inflate -lz || FAIL "dropbear needs zlib"

AC_CHECK_HEADERS netinet/tcp.h
AC_CHECK_HEADERS netinet/in_systm.h
if AC_CHECK_HEADERS netinet/in.h; then
    __hfile=netinet/in.h
    AC_CHECK_STRUCT sockaddr_storage $__hfile
    AC_CHECK_STRUCT in6_addr $__hfile
    if AC_CHECK_HEADERS sys/socket.h; then
	__hfile="$__hfile sys/socket.h"
    fi
    AC_CHECK_STRUCT sockaddr_in6 $__hfile
fi
AC_CHECK_HEADERS netdb.h && AC_CHECK_STRUCT addrinfo netdb.h
AC_CHECK_FUNCS basename
AC_CHECK_FUNCS clearenv
AC_CHECK_FUNCS freeaddrinfo
AC_CHECK_FUNCS getaddrinfo
AC_CHECK_FUNCS getnameinfo
AC_CHECK_FUNCS getpass
AC_CHECK_FUNCS getusershell
AC_CHECK_HEADERS inttypes.h
AC_CHECK_HEADERS lastlog.h
AC_CHECK_HEADERS libgen.h
AC_CHECK_HEADERS libutil.h
AC_CHECK_HEADERS login.h
AC_CHECK_HEADERS paths.h
AC_CHECK_HEADERS pty.h
AC_CHECK_HEADERS shadow.h
AC_CHECK_FUNCS strlcat
AC_CHECK_FUNCS strlcpy
AC_CHECK_HEADERS sys/uio.h
if AC_CHECK_HEADERS sys/types.h; then
    AC_CHECK_TYPE uint16_t sys/types.h
    AC_CHECK_TYPE uint32_t sys/types.h
    AC_CHECK_TYPE uint8_t sys/types.h
    AC_CHECK_TYPE u_int16_t sys/types.h
    AC_CHECK_TYPE u_int32_t sys/types.h
    AC_CHECK_TYPE u_int8_t sys/types.h
fi
AC_CHECK_HEADERS util.h
AC_CHECK_HEADERS utmpx.h
AC_CHECK_HEADERS utmp.h
AC_CHECK_FUNCS writev
AC_LIBRARY _getpty -lutil
AC_LIBRARY openpty -lutil
AC_CHECK_FUNCS memset_s

if AC_CHECK_HEADERS security/pam_appl.h; then
    __pamh=security/pam_appl.h
elif AC_CHECK_HEADERS pam/pam_appl.h; then
    __pamh=pam/pam_appl.h
fi

if [ "$__pamh" ]; then
    # is PAM_FAIL_DELAY defined in pam

cat > /tmp/__ngc$$.c << EOF
#include <stdio.h>
#include <$__pamh>
main()
{
    printf("PAM_FAIL_DELAY=%d\n", PAM_FAIL_DELAY);
}
EOF

    if AC_QUIET $AC_CC -c /tmp/__ngc$$.c ; then
	LOG "PAM_FAIL_DELAY is defined"
	AC_DEFINE 'HAVE_PAM_FAIL_DELAY' '1'
    fi
    rm -f /tmp/__ngc$$.o /tmp/__ngc$$.c
fi

AC_OUTPUT Makefile libtomcrypt/Makefile libtommath/Makefile
