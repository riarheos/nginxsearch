package nginxsearch;

use strict;
use warnings;
use nginx;
use utf8;

my %ENGINES = (
    'google' => 'https://www.google.ru/search?q=',
    'lucky'  => 'https://www.google.ru/search?btnI=1&q=',
    'yandex' => 'https://yandex.ru/yandsearch?text=',
    'host'   => 'https://golem.yandex-team.ru/hostinfo.sbml?object=',
    'jdict'  => 'http://ejje.weblio.jp/content/',
    'staff'  => 'https://staff.yandex-team.ru/',
    'st'     => 'https://st.yandex-team.ru/',
);

my %STATIC = (
    ''               => ['text/html', 'index.html'],
    'opensearch.xml' => ['text/xml', 'opensearch.xml'],
);

my @REPLACES = (
    # word     replacement            engine
    [ 'mysql', 'site:dev.mysql.com ', 'lucky' ],
    [ 'host',  '',                    'host'  ],
    [ 'g',     '',                    'google'],
    [ 'j',     '',                    'jdict'],
    [ 's',     '',                    'staff'],
    [ 'st',    '',                    'st'],
);

sub handler {
    my $r = shift;
    my $engine = 'google';

    # extract the query
    my $query = $r->filename;
    $query =~ s~.*/search/~~;
    utf8::decode($query);

    # statics
    if ($STATIC{$query}) {
        my $f;
        open ($f, "/Users/paulus/build/nginxsearch/$STATIC{$query}->[1]");
        my $data = join("", <$f>);
        close ($f);

        $r->send_http_header($STATIC{$query}->[0]);
        $r->print($data);
        return OK;
    }

    # russian letters
    if ($query =~ /[а-я]/i) {
        $engine = 'yandex';
    } elsif ($query =~ /[\x{4E00}-\x{9FBF}\x{3040}-\x{309F}\x{30A0}-\x{30FF}]/) {
        $engine = 'jdict';
    }

    # special replacements
    foreach (@REPLACES) {
        if ($query =~ /^$_->[0] /) {
            $query =~ s/^$_->[0]\s+/$_->[1]/;
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
