package nginxsearch;

use strict;
use warnings;
use nginx;

my %ENGINES = (
    'google' => 'https://www.google.ru/search?q=',
    'lucky'  => 'https://www.google.ru/search?btnI=1&q=',
    'yandex' => 'https://yandex.ru/yandsearch?text=',
    'host'   => 'https://golem.yandex-team.ru/hostinfo.sbml?object=',
);

my @REPLACES = (
    # word     replacement            engine
    [ 'mysql', 'site:dev.mysql.com ', 'lucky' ],
    [ 'host',  '',                    'host'  ],
);

sub handler {
    my $r = shift;
    my $engine = 'google';

    # extract the query
    my $query = $r->filename;
    $query =~ s~.*/search/~~;

    # russian letters
    if ($query =~ /[а-я]/i) {
        $engine = 'yandex';
    }

    # special replacements
    foreach (@REPLACES) {
        if ($query =~ /^$_->[0]/) {
            $query =~ s/^$_->[0]\s*/$_->[1]/;
            $engine = $_->[2];
            last;
        }
    }

    # do redirect
    if (1) {
        $r->status(302);
        $r->header_out('Location', $ENGINES{$engine} . $query);
        $r->send_http_header('');
    } else {
        $r->send_http_header('text/plain');
        $r->print($ENGINES{$engine} . $query);
    }
    return OK;
};

1;
