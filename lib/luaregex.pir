# Copyright (C) 2007, The Perl Foundation.
# $Id$

=head1 NAME

lib/luaregex.pir - Lua regex compiler

=head1 DESCRIPTION

See "Lua 5.1 Reference Manual", section 5.4.1 "Patterns",
L<http://www.lua.org/manual/5.1/manual.html#5.4.1>.

=head2 Character Class:

A I<character class> is used to represent a set of characters. The following
combinations are allowed in describing a character class:

=over 4

=item B<x>

(where I<x> is not one of the I<magic characters> C<^$()%.[]*+-?)> represents
the character I<x> itself.

=item B<.>

(a dot) represents all characters.

=item B<%a>

represents all letters.

=item B<%c>

represents all control characters.

=item B<%d>

represents all digits.

=item B<%l>

represents all lowercase letters.

=item B<%p>

represents all punctuation characters.

=item B<%s>

represents all space characters.

=item B<%u>

represents all uppercase letters.

=item B<%w>

represents all alphanumeric characters.

=item B<%x>

represents all hexadecimal digits.

=item B<%z>

represents the character with representation 0.

=item B<%x>

(where I<x> is any non-alphanumeric character) represents the character I<x>.
This is the standard way to escape the magic characters. Any punctuation
character (even the non magic) can be preceded by a C<'%'> when used to
represent itself in a pattern.

=item B<[set]>

represents the class which is the union of all characters in I<set>. A range of
characters may be specified by separating the end characters of the range with
a C<'-'>. All classes C<%x> described above may also be used as components in
I<set>. All other characters in I<set> represent themselves. For example,
C<[%w_]> (or C<[_%w]>) represents all alphanumeric characters plus the
underscore, C<[0-7]> represents the octal digits, and C<[0-7%l%-]> represents
the octal digits plus the lowercase letters plus the C<'-'> character.

The interaction between ranges and classes is not defined. Therefore, patterns
like C<[%a-z]> or C<[a-%%]> have no meaning.

=item B<[^set]>

represents the complement of I<set>, where I<set> is interpreted as above.

=back

For all classes represented by single letters (C<%a>, C<%c>, etc.), the
corresponding uppercase letter represents the complement of the class. For
instance, C<%S> represents all non-space characters.

The definitions of letter, space, and other character groups depend on the
current locale. In particular, the class C<[a-z]> may not be equivalent to
C<%l>.

=head2 Pattern Item:

A I<pattern item> may be

=over 4

=item *

a single character class, which matches any single character in the class;

=item *

a single character class followed by C<'*'>, which matches 0 or more
repetitions of characters in the class. These repetition items will always
match the longest possible sequence;

=item *

a single character class followed by C<'+'>, which matches 1 or more
repetitions of characters in the class. These repetition items will always
match the longest possible sequence;

=item *

a single character class followed by C<'-'>, which also matches 0 or more
repetitions of characters in the class. Unlike C<'*'>, these repetition items
will always match the I<shortest> possible sequence;

=item *

a single character class followed by C<'?'>, which matches 0 or 1
occurrence of a character in the class;

=item *

C<%n>, for I<n> between 1 and 9; such item matches a substring equal to
the i<n>-th captured string (see below);

=item *

C<%bxy>, where I<x> and I<y> are two distinct characters; such item
matches strings that start with I<x>, end with I<y>, and where the I<x> and
I<y> are I<balanced>. This means that, if one reads the string from left to
right, counting I<+1> for an I<x> and I<-1> for a I<y>, the ending I<y> is the
first I<y> where the count reaches 0. For instance, the item C<%b()> matches
expressions with balanced parentheses.

=back

=head2 Pattern:

A I<pattern> is a sequence of pattern items. A C<'^'> at the beginning of a
pattern anchors the match at the beginning of the subject string. A C<'$'> at
the end of a pattern anchors the match at the end of the subject string. At
other positions, C<'^'> and C<'$'> have no special meaning and represent
themselves.

=head2 Captures:

A pattern may contain sub-patterns enclosed in parentheses; they describe
I<captures>. When a match succeeds, the substrings of the subject string that
match captures are stored (I<captured>) for future use. Captures are numbered
according to their left parentheses. For instance, in the pattern
C<"(a*(.)%w(%s*))">, the part of the string matching C<"a*(.)%w(%s*)"> is
stored as the first capture (and therefore has number 1); the character
matching C<"."> is captured with number 2, and the part matching C<"%s*"> has
number 3.

As a special case, the empty capture C<()> captures the current string
position (a number). For instance, if we apply the pattern C<"()aa()"> on the
string C<"flaaap">, there will be two captures: 3 and 5.

A pattern cannot contain embedded zeros. Use C<%z> instead.

=head1 HISTORY

Mostly taken from F<compilers/pge/PGE/P5Regex.pir>.

=head1 AUTHOR

Francois Perrad

=cut

.sub "__onload" :load
    load_bytecode 'PGE.pbc'

    $P0 = getclass "PGE::Exp::CCShortcut"
    $P1 = subclass $P0, "PGE::Exp::LuaCCShortcut"
.end

.namespace [ "PGE::LuaRegex" ]

.sub "compile_luaregex"
    .param pmc source
    .param pmc adverbs         :slurpy :named

    $I0 = exists adverbs['name']
    if $I0 goto adverbs_1
    adverbs['name'] = '_luaregex'
  adverbs_1:
    $I0 = exists adverbs['grammar']
    if $I0 goto adverbs_2
    adverbs['grammar'] = 'PGE::Grammar'
  adverbs_2:

    .local string target
    target = adverbs['target']
    target = downcase target

    .local pmc match
    $P0 = get_global "luaregex"
    match = $P0(source)
    if target != 'parse' goto check
    .return (match)

  check:
    unless match goto check_1
    $S0 = source
    $S1 = match
    if $S0 == $S1 goto analyze
  check_1:
    null $P0
    .return ($P0)

  analyze:
    .local pmc exp, pad
    exp = match['expr']
    pad = new .Hash
    pad['subpats'] = 0
    exp = exp.'luaanalyze'(pad)
    .return exp.'compile'(adverbs :flat :named)
.end


.sub "luaregex"
    .param pmc mob
    .local pmc optable
    optable = get_hll_global ["PGE::LuaRegex"], "$optable"
    $P0 = optable."parse"(mob)
    .return ($P0)
.end


.include "cclass.pasm"


.sub "__onload" :load
    .local pmc optable

    $I0 = find_type "PGE::OPTable"
    optable = new $I0
    set_hll_global ["PGE::LuaRegex"], "$optable", optable

    $P0 = get_hll_global ["PGE::LuaRegex"], "parse_lit"
    optable.newtok('term:', 'precedence'=>'=', 'nows'=>1, 'parsed'=>$P0)

    optable.newtok('term:^',   'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::Anchor')
    optable.newtok('term:$',   'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::Anchor')

    optable.newtok('term:%a', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%A', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%c', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%C', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%d', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%D', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%l', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%L', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%p', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%P', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%s', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%S', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%u', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%U', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%w', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%W', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%x', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
    optable.newtok('term:%X', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
#    optable.newtok('term:%z', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')
#    optable.newtok('term:%Z', 'equiv'=>'term:', 'nows'=>1, 'match'=>'PGE::Exp::LuaCCShortcut')

    optable.newtok('circumfix:( )',   'equiv'=>'term:', 'nows'=>1, 'nullterm'=>1, 'match'=>'PGE::Exp::CGroup')

    $P0 = get_hll_global ['PGE::LuaRegex'], 'parse_enumclass'
    optable.newtok('term:[', 'precedence'=>'=', 'nows'=>1, 'parsed'=>$P0)
    optable.newtok('term:.', 'precedence'=>'=', 'nows'=>1, 'parsed'=>$P0)

    $P0 = get_hll_global ['PGE::LuaRegex'], 'parse_quant'
    optable.newtok('postfix:*', 'looser'=>'term:', 'left'=>1, 'nows'=>1, 'parsed'=>$P0)
    optable.newtok('postfix:+', 'equiv'=>'postfix:*', 'left'=>1, 'nows'=>1, 'parsed'=>$P0)
    optable.newtok('postfix:?', 'equiv'=>'postfix:*', 'left'=>1, 'nows'=>1, 'parsed'=>$P0)
    optable.newtok('postfix:-', 'equiv'=>'postfix:*', 'left'=>1, 'nows'=>1, 'parsed'=>$P0)

    optable.newtok('infix:',  'looser'=>'postfix:*', 'right'=>1, 'nows'=>1, 'match'=>'PGE::Exp::Concat')

    $P0 = get_hll_global ["PGE::LuaRegex"], "compile_luaregex"
    compreg "PGE::LuaRegex", $P0
.end


.sub 'parse_error'
    .param pmc mob
    .param int pos
    .param string message
    $P0 = getattribute mob, '$.pos'
    $P0 = pos
    $P0 = new .Exception
    $S0 = 'luaregex parse error: '
    $S0 .= message
    $S0 .= ' at offset '
    $S1 = pos
    $S0 .= $S1
    $S0 .= ", found '"
    $P1 = getattribute mob, '$.target'
    $S1 = $P1
    $S1 = substr $S1, pos, 1
    $S0 .= $S1
    $S0 .= "'"
    $P0['_message'] = $S0
    throw $P0
    .return ()
.end


.sub "parse_lit"
    .param pmc mob
    .local pmc newfrom
    .local string target
    .local int pos, lastpos
    .local int litstart, litlen
    .local string initchar
    newfrom = get_hll_global ["PGE::Match"], "newfrom"
    (mob, target, $P0, $P1) = newfrom(mob, 0, "PGE::Exp::Literal")
    pos = $P0
    lastpos = length target
    initchar = substr target, pos, 1
    unless initchar == '*' goto initchar_ok
    parse_error(mob, pos, "Quantifier follows nothing")

  initchar_ok:
    if initchar == ')' goto end
    inc pos
  term_percent:
    if initchar != '%' goto term_backslash
    initchar = substr target, pos, 1
    inc pos
    if pos <= lastpos goto term_percent_ok
    parse_error(mob, pos, "Search pattern not terminated")
  term_percent_ok:
    goto term_literal
  term_backslash:
    if initchar != "\\" goto term_literal
    initchar = substr target, pos, 1
    inc pos
    if pos <= lastpos goto term_backslash_ok
    parse_error(mob, pos, "Search pattern not terminated")
  term_backslash_ok:
    $I0 = index "abfnrtv", initchar
    if $I0 < 0 goto term_literal
    initchar = substr "\a\b\f\n\r\t\x0b", $I0, 1
  term_literal:
    litstart = pos
    litlen = 0
  term_literal_loop:
    if pos >= lastpos goto term_literal_end
    $S0 = substr target, pos, 1
    $I0 = index "^$()%.[]*+-?", $S0
    # if not in circumfix:( ) throw error on end paren
    if $I0 >= 0 goto term_literal_end
    inc pos
    inc litlen
    goto term_literal_loop
  term_literal_end:
    if litlen < 1 goto term_literal_one
    dec pos
  term_literal_one:
    $I0 = pos - litstart
    $S0 = substr target, litstart, $I0
    $S0 = concat initchar, $S0
    mob.'result_object'($S0)
    goto end
  end:
    $P0 = getattribute mob, "PGE::Match\x0$.pos"
    $P0 = pos
    .return (mob)
.end

.const int PGE_INF = 2147483647
.const int PGE_BACKTRACK_GREEDY = 1
.const int PGE_BACKTRACK_EAGER = 2

.sub "parse_quant"
    .param pmc mob
    .local string target
    .local int min, max, backtrack
    .local int pos, lastpos
    .local pmc mfrom, mpos
    .local string key
    key = mob['KEY']
    $P0 = get_hll_global ["PGE::Match"], "newfrom"
    (mob, target, mfrom, mpos) = $P0(mob, 0, "PGE::Exp::Quant")
    pos = mfrom
    lastpos = length target
    min = 0
    max = PGE_INF
    backtrack = PGE_BACKTRACK_GREEDY
    if key != '+' goto quant_max
    min = 1
  quant_max:
    if key != "?" goto quant_eager
    max = 1
  quant_eager:
    if key != "-" goto end
    backtrack = PGE_BACKTRACK_EAGER
  end:
    mob["min"] = min
    mob["max"] = max
    mob["backtrack"] = backtrack
    mpos = pos
    .return (mob)
  err_range:
    parse_error(mob, pos, "Error in quantified range")
.end


.sub "parse_enumclass"
    .param pmc mob
    .local string target
    .local pmc mfrom, mpos
    .local int pos, lastpos
    .local int isrange
    .local string charlist
    .local string key
    key = mob['KEY']
    $P0 = get_hll_global ["PGE::Match"], "newfrom"
    (mob, target, mfrom, mpos) = $P0(mob, 0, "PGE::Exp::EnumCharList")
    pos = mfrom
    if key == '.' goto dot
    lastpos = length target
    charlist = ""
    mob["isnegated"] = 0
    isrange = 0
    $S0 = substr target, pos, 1
    if $S0 != "^" goto scan_first
    mob["isnegated"] = 1
    inc pos
  scan_first:
    if pos >= lastpos goto err_close
    $S0 = substr target, pos, 1
    inc pos
    if $S0 == "\\" goto backslash
    goto addchar
  scan:
    if pos >= lastpos goto err_close
    $S0 = substr target, pos, 1
    inc pos
    if $S0 == "]" goto endclass
    if $S0 == "-" goto hyphenrange
    if $S0 != "\\" goto addchar
  backslash:
    $S0 = substr target, pos, 1
    inc pos
    $I0 = index "nrtfae0b", $S0
    if $I0 == -1 goto addchar
    $S0 = substr "\n\r\t\f\a\e\0\b", $I0, 1
  addchar:
    if isrange goto addrange
    charlist .= $S0
    goto scan
  addrange:
    isrange = 0
    $I2 = ord charlist, -1
    $I0 = ord $S0
    if $I0 < $I2 goto err_range
  addrange_1:
    inc $I2
    if $I2 > $I0 goto scan
    $S1 = chr $I2
    charlist .= $S1
    goto addrange_1
  hyphenrange:
    if isrange goto addrange
    isrange = 1
    goto scan
  endclass:
    if isrange == 0 goto end
    charlist .= "-"
    goto end
  dot:
    charlist = "\n"
    mob["isnegated"] = 1
  end:
    mpos = pos
    mob.'result_object'(charlist)
    .return (mob)

  err_close:
    parse_error(mob, pos, "Unmatched [")
  err_range:
    $S0 = 'Invalid [] range "'
    $S1 = chr $I2
    $S0 .= $S1
    $S0 .= '-'
    $S1 = chr $I0
    $S0 .= $S1
    $S0 .= '"'
    parse_error(mob, pos, $S0)
.end


.namespace [ "PGE::Exp" ]

.sub "luaanalyze" :method
    .param pmc pad
    .local pmc exp
    $I0 = 0
  loop:
    $I1 = defined self[$I0]
    if $I1 == 0 goto end
    $P0 = self[$I0]
    $P0 = $P0."luaanalyze"(pad)
    self[$I0] = $P0
    inc $I0
    goto loop
  end:
    .return (self)
.end

.namespace [ "PGE::Exp::CGroup" ]

.sub "luaanalyze" :method
    .param pmc pad
    .local pmc exp

    self["iscapture"] = 0
    if self != "(" goto end
    self["iscapture"] = 1
    self["isscope"] = 0
    self["isarray"] = 0
    $I0 = pad["subpats"]
    self["cname"] = $I0
    inc $I0
    pad["subpats"] = $I0
  end:
    exp = self[0]
    exp = exp."luaanalyze"(pad)
    self[0] = exp
    .return (self)
.end

.namespace [ 'PGE::Exp::LuaCCShortcut' ]

.sub 'reduce' :method
    .param pmc next

    .local string token
    token = self
    self['negate'] = 1
    if token == '%A' goto letter
    if token == '%C' goto ctrl
    if token == '%D' goto digit
    if token == '%L' goto lower
    if token == '%P' goto ponct
    if token == '%S' goto space
    if token == '%U' goto upper
    if token == '%W' goto word
    if token == '%X' goto hexa
#    if token == '%Z' goto z
    self['negate'] = 0
    if token == '%a' goto letter
    if token == '%c' goto ctrl
    if token == '%d' goto digit
    if token == '%l' goto lower
    if token == '%p' goto ponct
    if token == '%s' goto space
    if token == '%u' goto upper
    if token == '%w' goto word
    if token == '%x' goto hexa
#    if token == '%z' goto z
    self['cclass'] = .CCLASS_ANY
    goto end
  letter:
    self['cclass'] = .CCLASS_ALPHABETIC
    goto end
  ctrl:
    self['cclass'] = .CCLASS_CONTROL
    goto end
  digit:
    self['cclass'] = .CCLASS_NUMERIC
    goto end
  lower:
    self['cclass'] = .CCLASS_LOWERCASE
    goto end
  ponct:
    self['cclass'] = .CCLASS_PUNCTUATION
    goto end
  space:
    self['cclass'] = .CCLASS_WHITESPACE
    goto end
  upper:
    self['cclass'] = .CCLASS_UPPERCASE
    goto end
  word:
    self['cclass'] = .CCLASS_WORD
    goto end
  hexa:
    self['cclass'] = .CCLASS_HEXADECIMAL
  end:
    .return (self)
.end
