class Wee::Routes::Match {
    has $.path;
    has %.args;
    has %.captures;
}

grammar Wee::Routes::Grammar {
    regex TOP {
        ^ [ \/ | <path>* ] $
    }
    regex path    { \/ [ <text> | <capture> ] }
    regex text    { (<-[\:\/]>+) }
    regex capture { \: (<-[\:\/]>+) }
}

class Wee::Routes::Actions {
    method TOP($/) {
        my @tree;

        for $<path>.list -> $c {
            @tree.push($c.ast);
        }

        make @tree;
    }
    method path($/) {
        make $<capture>.ast if $<capture>;
        make $<text>.ast if $<text>;
    }
    method text($/) { make %( text => $0 ) }
    method capture($/) { make %( capture => $0 ) }
}

class Wee::Routes {
    has @!routes;

    method add ($route, *%args) {
        my $match = Wee::Routes::Grammar.parse($route, :actions(Wee::Routes::Actions));
        die 'Cannot parse route' unless $match;

        my @parts = $match.ast;

        # Spaces in regex are working because we use EVAL. Otherwise they don't.
        # Beware!
        my @re;
        for @parts -> $part {
            if my $name = $part<capture> {
                @re.push("\$<$name>=<-[\\:\\/]>+");
            }
            else {
                @re.push("$part<text>");
            }
        }

        my $re = '^ \\/ ' ~ @re.join(' \\/ ') ~ ' $';

        #warn $re;

        # This was a long battle trying to compile a string into a working regex
        # (with named captures and stuff). EVAL isn't the nicest thing, but at
        # least it works, and we will compile it just once anyway
        my $regex = EVAL "/$re/";

        @!routes.push({
            re    => $regex,
            args  => %args || {},
            parts => @parts
        });
    }

    method match ($path, *%args) {
        my %match;

        # Labels do not work in 2014.09
        ROUTE: for @!routes -> %route {
            my $re = %route<re>;

            # <re=$re> is needed so the named captures work
            if $path.match(/<re=$re>/) {
                for %args.kv -> $key, $value {
                    next ROUTE if %route<args>{$key}:exists
                        && %route<args>{$key} ne $value;
                }

                %match<args> = %(%route<args>);
                %match<captures> = $<re>.hash;

                last;
            }
        }

        return unless %match.elems;

        return Wee::Routes::Match.new(
            path => $path,
            captures => %match<captures>,
            args => %match<args>
        );
    }
}
