#! ../../parrot
# Copyright (C) 2009, Parrot Foundation.
# $Id$

=head1 LuaString

=head2 Synopsis

    % parrot t/pmc/string.t

=head2 Description

Tests C<LuaString> PMC
(implemented in F<languages/lua/src/pmc/luastring.pmc>).

=cut

.sub 'main' :main
    loadlib $P0, 'lua_group'

    .include 'test_more.pir'

    plan(11)

    check_inheritance()
    check_interface()
    check_name()
    check_get_bool()
    check_logical_not()
    check_embedded_zero()
.end

.sub 'check_inheritance'
    $P0 = new 'LuaString'
    $I0 = isa $P0, 'LuaAny'
    is($I0, 1)
    $I0 = isa $P0, 'LuaString'
    is($I0, 1)
.end

.sub 'check_interface'
    $P0 = new 'LuaString'
    $I0 = does $P0, 'scalar'
    is($I0, 1)
    $I0 = does $P0, 'string'
    is($I0, 1)
    $I0 = does $P0, 'no_interface'
    is($I0, 0)
.end

.sub 'check_name'
    $P0 = new 'LuaString'
    $S0 = typeof $P0
    is($S0, 'string')
.end

.sub 'check_get_bool'
    $P0 = new 'LuaString'
    set $P0, 'str'
    $I0 = istrue $P0
    is($I0, 1)
    set $P0, ''
    $I0 = istrue $P0
    is($I0, 1)
.end

.sub 'check_logical_not'
    $P0 = new 'LuaString'
    set $P0, 'str'
    $P1 = not $P0
    $S0 = $P1
    is($S0, 'false')
    $S0 = typeof $P1
    is($S0, 'boolean')
.end

.sub 'check_embedded_zero'
    $P0 = new 'LuaString'
    set $P0, "embe\0_dd\0_ed\0"
    $I0 = elements $P0
    is($I0, 13)
.end

# Local Variables:
#   mode: pir
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

