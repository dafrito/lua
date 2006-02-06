# Copyright: 2005-2006 The Perl Foundation.  All Rights Reserved.
# $Id$

=head1 NAME

lib/luaos.pir - Lua Operating System Library

=head1 DESCRIPTION

This library is implemented through table C<os>.

See "Lua 5.0 Reference Manual", section 5.7 "Operating System Facilities".

=head2 Functions

=over 4

=cut

.namespace [ "Lua" ]
.HLL "Lua", "lua_group"


.sub init :load, :anon

    load_bytecode "languages/lua/lib/luapir.pbc"
    load_bytecode "languages/lua/lib/luabasic.pbc"

#    print "init Lua OS\n"

    .local pmc _lua__G
    _lua__G = global "_G"
    $P1 = new .LuaString

    .local pmc _os
    _os = new .LuaTable
    $P1 = "os"
    _lua__G[$P1] = _os

    .const .Sub _os_clock = "_os_clock"
    $P0 = _os_clock
    $P1 = "clock"
    _os[$P1] = $P0

    .const .Sub _os_date = "_os_date"
    $P0 = _os_date
    $P1 = "date"
    _os[$P1] = $P0

    .const .Sub _os_difftime = "_os_difftime"
    $P0 = _os_difftime
    $P1 = "difftime"
    _os[$P1] = $P0

    .const .Sub _os_execute = "_os_execute"
    $P0 = _os_execute
    $P1 = "execute"
    _os[$P1] = $P0

    .const .Sub _os_exit = "_os_exit"
    $P0 = _os_exit
    $P1 = "exit"
    _os[$P1] = $P0

    .const .Sub _os_getenv = "_os_getenv"
    $P0 = _os_getenv
    $P1 = "getenv"
    _os[$P1] = $P0

    .const .Sub _os_remove = "_os_remove"
    $P0 = _os_remove
    $P1 = "remove"
    _os[$P1] = $P0

    .const .Sub _os_rename = "_os_rename"
    $P0 = _os_rename
    $P1 = "rename"
    _os[$P1] = $P0

    .const .Sub _os_setlocale = "_os_setlocale"
    $P0 = _os_setlocale
    $P1 = "setlocale"
    _os[$P1] = $P0

    .const .Sub _os_time = "_os_time"
    $P0 = _os_time
    $P1 = "time"
    _os[$P1] = $P0

    .const .Sub _os_tmpname = "_os_tmpname"
    $P0 = _os_tmpname
    $P1 = "tmpname"
    _os[$P1] = $P0

.end

=item C<os.clock ()>

Returns an approximation of the amount of CPU time used by the program, in
seconds.

NOT YET IMPLEMENTED.

=cut

.sub _os_clock :anon
    .local pmc ret
    new ret, .LuaNumber
    not_implemented()
.end

=item C<os.date ([format [, time]])>

Returns a string or a table containing date and time, formatted according to
the given string C<format>.

If the C<time> argument is present, this is the time to be formatted (see
the C<os.time> function for a description of this value). Otherwise, C<date>
formats the current time.

If C<format> starts with C<�!�>, then the date is formatted in Coordinated
Universal Time. After that optional character, if C<format> is C<*t>, then
C<date> returns a table with the following fields: C<year> (four digits),
C<month> (1-12), C<day> (1-31), C<hour> (0-23), C<min> (0-59), C<sec> (0-61),
C<wday> (weekday, Sunday is 1), C<yday> (day of the year), and C<isdst>
(daylight saving flag, a boolean).

If C<format> is not C<*t>, then C<date> returns the date as a string,
formatted according with the same rules as the C function C<strftime>.

When called without arguments, C<date> returns a reasonable date and time
representation that depends on the host system and on the current locale
(that is, C<os.date()> is equivalent to C<os.date("%c")>).

NOT YET IMPLEMENTED.

=cut

.sub _os_date :anon
    .param pmc format :optional
    .param pmc time :optional
    $S0 = optstring(format, "%c")
    $I0 = optint(time, -1)
    not_implemented()
.end

=item C<os.difftime (t2, t1)>

Returns the number of seconds from time C<t1> to time C<t2>. In Posix,
Windows, and some other systems, this value is exactly C<t2-t1>.

NOT YET IMPLEMENTED.

=cut

.sub _os_difftime :anon
    .param pmc t2
    .param pmc t1
    $I0 = checkint(t2)
    $I1 = optint(t1, 0)
    not_implemented()
.end

=item C<os.execute (command)>

This function is equivalent to the C function C<system>. It passes C<command>
to be executed by an operating system shell. It returns a status code, which
is system-dependent.

=cut

.sub _os_execute :anon
    .param pmc command
    .local pmc ret
    $S0 = checkstring(command)
    $I0 = spawnw $S0
    $I0 = $I0 / 256
    new ret, .LuaNumber
    ret = $I0
    .return (ret)
.end

=item C<os.exit ([code])>

Calls the C function C<exit>, with an optional C<code>, to terminate the host
program. The default value for C<code> is the success code.

=cut

.sub _os_exit :anon
    .param pmc code :optional
    $I0 = optint(code, 0)
    exit $I0
.end

=item C<os.getenv (varname)>

Returns the value of the process environment variable C<varname>, or B<nil>
if the variable is not defined.

=cut

.sub _os_getenv :anon
    .param pmc varname
    .local pmc ret
    $S0 = checkstring(varname)
    new $P0, .Env
    $S1 = $P0[$S0]
    if $S1 goto L0
    new ret, .LuaNil
    .return (ret)
L0:
    new ret, .LuaString
    ret = $S1
    .return (ret)
.end

=item C<os.remove (filename)>

Deletes the file with the given name. If this function fails, it returns
B<nil>, plus a string describing the error.

=cut

.sub _os_remove :anon
    .param pmc filename
    .local pmc ret
    $S0 = checkstring(filename)
    new $P0, .OS
    push_eh _handler
    $P0."rm"($S0)
    new ret, .LuaBoolean
    ret = 1
    .return (ret)
_handler:
    .local pmc nil
    .local pmc msg
    .local pmc e
    .local string s
    .get_results (e, s)
    concat $S0, ": "
    concat $S0, s
    new nil, .LuaNil
    new msg, .LuaString
    msg = $S0
    .return (nil, msg)
.end

=item C<os.rename (oldname, newname)>

Renames file named C<oldname> to C<newname>. If this function fails, it
returns B<nil>, plus a string describing the error.

NOT YET IMPLEMENTED.              

=cut

.sub _os_rename :anon
    .param pmc oldname
    .param pmc newname
    $S0 = checkstring(oldname)
    $S1 = checkstring(newname)
    not_implemented()
.end

=item C<os.setlocale (locale [, category])>

Sets the current locale of the program. C<locale> is a string specifying a
locale; C<category> is an optional string describing which category to change:
C<"all">, C<"collate">, C<"ctype">, C<"monetary">, C<"numeric">, or C<"time">;
the default category is C<"all">. The function returns the name of the new
locale, or B<nil> if the request cannot be honored.

NOT YET IMPLEMENTED.

=cut

.sub _os_setlocale :anon
    .param pmc locale
    .param pmc category :optional
    $S1 = optstring(category, "all")
    not_implemented()
.end

=item C<os.time ([table])>

Returns the current time when called without arguments, or a time representing
the date and time specified by the given table. This table must have fields
C<year>, C<month>, and C<day>, and may have fields C<hour>, C<min>, C<sec>,
and C<isdst> (for a description of these fields, see the C<os.date> function).

The returned value is a number, whose meaning depends on your system. In
Posix, Windows, and some other systems, this number counts the number of
seconds since some given start time (the "epoch"). In other systems, the
meaning is not specified, and the number returned by C<time> can be used only
as an argument to C<date> and C<difftime>.

STILL INCOMPLETE.

=cut

.sub _os_time :anon
    .param pmc table :optional
    .local pmc ret
    if_null table, L0
    $S0 = typeof table
    if $S0 != "nil" goto L1
L0:
    $I0 = time
    new ret, .LuaNumber
    ret = $I0
    .return (ret)
L1:
    checktype(table, "table")
    not_implemented()
.end

=item C<os.tmpname ()>

Returns a string with a file name that can be used for a temporary file. The file must be explicitly
opened before its use and removed when no longer needed.

This function is equivalent to the C<tmpnam> C function, and many people (and
even some compilers!) advise against its use, because between the time you
call this function and the time you open the file, it is possible for another
process to create a file with the same name.

NOT YET IMPLEMENTED.

=cut

.sub _os_tmpname :anon
    .local pmc ret
    new ret, .LuaString
    not_implemented()
.end

=back

=head1 AUTHORS

Francois Perrad.

=cut
