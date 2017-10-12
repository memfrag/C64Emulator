/*
 * coproc.c - co-process fork
 *
 * Written by
 *  Andre Fachat <a.fachat@physik.tu-chemnitz.de>
 *
 * Patches by
 *
 * This file is part of VICE, the Versatile Commodore Emulator.
 * See README for copyright notice.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 *  02111-1307  USA.
 *
 */

/*
 * This is modelled after some examples in Stevens, "Advanced Progamming
 * in the Unix environment", Addison Wesley.
 *
 * It simply opens two uni-directional pipes and forks a process to
 * use the pipes as bidirectional connection for the stdin/out of the
 * child.
 * This, however, implies that the child knows its being piped and _buffers_
 * all stdio. To avoid that one has to open a pseudo terminal device,
 * which is too heavily system dependant to be included here.
 * Instead a wrapper like the program "pty" described in the book mentioned
 * above could be used.
 *
 * Technicalities: It does not store the PID of the forked child but
 * instead it relies on the child being killed when the parent terminates
 * prematurely or the child terminates itself on EOF on stdin.
 *
 * The command string is given to "/bin/sh -c cmdstring" such that
 * the shell can do fileexpansion.
 *
 * We ignore all SIGCHLD and SIGPIPE signals that may occur here by
 * installing an ignoring handler.
 */

#include "vice.h"

#if !defined(MINIX_SUPPORT) && !defined(OPENSTEP_COMPILE) && !defined(RHAPSODY_COMPILE) && !defined(NEXTSTEP_COMPILE)

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>

#ifdef OPENSERVER6_COMPILE
#include <sys/signal.h>
#endif

#include "coproc.h"

#include "log.h"

#define SHELL "/bin/sh"

#ifndef sigset_t
#define sigset_t int
#endif

/* HP-UX 9 fix */
#ifndef SA_RESTART
#define SA_RESTART 0
#endif

#ifdef __NeXT__
int sigaction(int sig, const struct sigaction *act, struct sigaction *oact)
{
    struct sigvec vec, ovec;
    int st;

    vec.sv_handler = act->sa_handler;
    vec.sv_mask = act->sa_mask;
    vec.sv_flags = act->sa_flags;

    st = sigvec(sig, &vec, &ovec);

    if (oact) {
        oact->sa_handler = ovec.sv_handler;
        oact->sa_mask = ovec.sv_mask;
        oact->sa_flags = ovec.sv_flags;
    }
    return st;
}

int sigemptyset(sigset_t *set)
{
    *set = 0;
    return 0;
}
#endif

static struct sigaction ignore;

int fork_coproc(int *fd_wr, int *fd_rd, char *cmd)
{
    // Don't use on iOS or tvOS
    return 0;
}
#endif
