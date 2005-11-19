#!/usr/bin/perl -w

# Copyright 1999-2005, Paul Johnson (pjcj@cpan.org)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.pjcj.net

# Version 1.15 - 3rd May 2005

use strict;

use lib -d "t" ? "t" : "..";

BEGIN
{
    eval
    q{
        use 5.006;
        use Apache::Test ":withtestmore";
        use Apache::TestUtil;
        use LWP::Simple;
        use Test::JSON;
    };

    if (my $e = $@)
    {
        eval "use Test::More skip_all => " .
             "q[mod_perl or Test::JSON not fully installed [$e]]";
    }
}

use Test::More;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || "";

my $ws   = "/ws/json/royal";
my $root = "http://$hostport$ws";

sub ws { join "", map "$ws/$_\n",                  @_ }
sub rs { join "", map {chomp(my $t = $_); "$t\n" } @_ }

my @tests =
(
    [ "?search=Elizabeth_II", ws "I9"                                    ],
    [ "/i9/name",             rs "Elizabeth_II Alexandra Mary /Windsor/" ],
    [ "/i9/children",         ws qw( I11 I15 I19 I23 )                   ],
    [ "/i9/birth/date",       "Wednesday, 21st April 1926\n"             ],
    [ "/i9/birth",            rs <<'EOR'                                 ],
1   BIRT
2     DATE Wednesday, 21st April 1926
2     PLAC 17 Bruton St.,London,W1,England
EOR
    [ "/i9",                  rs <<'EOR'                                 ],
0 @I9@ INDI
1   NAME Elizabeth_II Alexandra Mary/Windsor/
1   TITL Queen of England
1   SEX F
1   BIRT
2     DATE Wednesday, 21st April 1926
2     PLAC 17 Bruton St.,London,W1,England
1   FAMS @F6@
1   FAMC @F4@
1   RIN 10

EOR
    [ "/i9/write",            rs <<'EOR'                                 ],
0 @I9@ INDI
1   NAME Elizabeth_II Alexandra Mary/Windsor/
1   TITL Queen of England
1   SEX F
1   BIRT
2     DATE Wednesday, 21st April 1926
2     PLAC 17 Bruton St.,London,W1,England
1   FAMS @F6@
1   FAMC @F4@
1   RIN 10

EOR
    [ "/i9/write_xml",        rs <<'EOR'                                 ],
<INDI ID="I9">
  <NAME>Elizabeth_II Alexandra Mary/Windsor/</NAME>
  <TITL>Queen of England</TITL>
  <SEX>F</SEX>
  <BIRT>
    <DATE>Wednesday, 21st April 1926</DATE>
    <PLAC>17 Bruton St.,London,W1,England</PLAC>
  </BIRT>
  <FAMS REF="F6"/>
  <FAMC REF="F4"/>
  <RIN>10</RIN>
</INDI>

EOR
    [ "/i0",                  "Can't get record [i0]\n"                  ],
    [ "/I9/__error__",        "Invalid action [__error__]\n"             ],
    [ "",                     "No xref or parameters specified\n"        ],
);

plan tests => 2;

is_valid_json get("http://$hostport/ws/json/royal/i9/name"),
              "... json well formed";

is_json get("http://$hostport/ws/json/royal/i9/name"),
        '{"result":"Elizabeth_II Alexandra Mary /Windsor/"}',
        "... json correct";

__END__

plan tests => scalar @tests + 2;

for (@tests)
{
    my $q = $root . $_->[0];
    # t_debug("-- $q");
    # t_debug("++ ", get($q));
    is get($q), $_->[1], $q;
}

is get("http://$hostport/ws/plain/"),
   "No GEDCOM file specified\n",
   "No GEDCOM file specified";

like get("http://$hostport/ws/plain/__error__"),
     qr!Can't open file .*/__error__.ged: No such file or directory!,
     "GEDCOM file does not exist";