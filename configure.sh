#! /bin/sh

# local options:  ac_help is the help message that describes them
# and LOCAL_AC_OPTIONS is the script that interprets them.  LOCAL_AC_OPTIONS
# is a script that's processed with eval, so you need to be very careful to
# make certain that what you quote is what you want to quote.

ac_help='--with-pam		Use pam for server authentication
--with-passwd		use passwd authentication (does not coexist with pam)'

# load in the configuration file
#
TARGET=dropbear
. ./configure.inc

AC_INIT $TARGET

AC_PROG_CC

if [ "$WITH_PAM" ]; then
    if AC_LIBRARY pam_authenticate -lpam; then
	AC_DEFINE 'DROPBEAR_SVR_PAM_AUTH' '1'
	AC_SUB 'CRYPTLIB' ''
    else
	AC_FAIL "configured --with-pam, but no pam library found?"
    fi
fi
if [ "$WITH_PASSWD" ]; then
    if [ "$WITH_PAM" ]; then
	AC_FAIL "cannot sensibly do passwd & pam authentication"
    else
	if AC_LIBRARY crypt -lcrypt; then
	    AC_DEFINE 'DROPBEAR_SVR_PASSWD_AUTH' '1'
	    AC_SUB CRYPTLIB '-lcrypt'
	else
	    AC_FAIL "--with-passwd requires a crypt() function"
	fi
    fi
fi

LOG "Building with ${WITH_PAM:+pam}${WITH_PASSWD:+passwd} authentication"

AC_SUB 'BUNDLED_LIBTOM' '1'
AC_DEFINE 'BUNDLED_LIBTOM' 1
AC_SUB 'EXEEXT' ''

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

# welcome to the horrible horrible land of utmp;
# check for utmpx, then a bunch of utmpx fields,
# and if that fails check for utmp and a bunch of
# utmp fields, and if that fails maybe hand it off
# to login?
AC_LIBRARY login -lutil && AC_CHECK_FUNCS logout
if AC_CHECK_HEADERS utmpx.h; then
    AC_DEFINE DISABLE_UTMP 1
    for field in ut_host ut_syslen ut_type ut_id ut_addr ut_addr_v6 ut_time ut_tv; do
	AC_CHECK_FIELD  utmpx $field utmpx.h
    done
elif AC_CHECK_HEADER utmp.h; then
    AC_DEFINE DISABLE_UTMPX 1
    for field in ut_host ut_pid ut_type ut_tv ut_id ut_addr ut_addr_v6 ut_exit ut_time; do
	AC_CHECK_FIELD utmp $field utmp.h
    done
else
    AC_DEFINE DISABLE_UTMPX 1
    AC_DEFINE DISABLE_UTMP 1
fi

AC_CHECK_FUNCS logwtmp
AC_CHECK_FUNCS logwtmpx

AC_CHECK_HEADERS util.h
AC_CHECK_FUNCS writev
AC_LIBRARY openpty -lutil
AC_LIBRARY _getpty -lutil

if AC_CHECK_FUNCS explicit_bzero || AC_CHECK_FUNCS memset_s; then
    : Yay
else
    LOG "Whoops: leaving a big old security hole here"
    AC_DEFINE 'explicit_bzero(x,s)' 'memset(x, 0, s)'
fi


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
