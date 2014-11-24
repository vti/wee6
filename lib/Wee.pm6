module Wee;

my %APP;
init;

sub init () is export {
    %APP = ();
}

sub include_templates ($templates) is export {
    for $templates.split(/^^\@\@\s+/).grep({$_ ne ""}) -> $include {
        my ($name, $content) = $include.split(/\n/, 2);

        %APP<includes>{$name} = $content.chomp;
    }
}

sub route ($method, $path, $handler) {
    my $ref = $handler ~~ Callable ?? $handler !! sub { $handler };

    %APP<routes>{$method}{$path} = $ref;
}

sub get  (*@rest) is export { route('GET',  |@rest) }
sub post (*@rest) is export { route('POST', |@rest) }

sub http_error ($message, $code = 500) is export {
    my $output = $message;
    try {
        $output = render($code, code => $code, message => $message);
    }

    return [$code, [], [$output]];
}

sub redirect ($url, $code = 302) is export {
    return [$code, [Location => $url], ['']];
}

sub html_escape ($input is copy) is export {
    $input.trans:
        /'&'/  => '&amp;',
        /'"'/  => '&quot;',
        /'<'/  => '&lt;',
        /'>'/  => '&gt;',
        /\xA0/ => '&nbsp;',
        ;
}

sub render ($name, *%vars) is export {
    my $template = $name ~~ Capture ?? ~$name !! %APP<includes>{$name}
      or die "Template not found";

    my $ref = $template ~~ Callable ?? $template !! compile_template($template);
    %APP<includes>{$name} = $ref unless $ref ~~ \Str;

    %vars<html_escape> //= &html_escape;
    return $ref.(%vars);
}

sub compile_template ($template) {
    grammar Template {
        regex TOP {
            ^ <chunk>* <leftover> $
        }
        regex chunk { <text> [ <inline> | <line> ] }
        regex text { .*?}
        regex code { <mode> \h* (.*?)}
        regex line { ^^ <line_start> <code> \s* [ \n | $ ] }
        regex inline {<start> <code> \s* <end>}
        token line_start {'%'}
        token start {'<%'}
        token end {'%>'}
        token mode {\= ** 0..2}
        regex leftover {.*}
    }

    class Template::Actions {
        method TOP($/) {
            my $code = 'sub (%vars) {my $_T;';

            my @chunks;
            for $<chunk>.list -> $c {
                @chunks.push($c.ast);
            }

            $code ~= join ';', @chunks, $<leftover>.ast;
            $code ~= '$_T;}';

            make $code;
        }
        method chunk($/) {
            my @v = $<text>.ast;
            @v.push($<inline>.ast) if $<inline>;
            @v.push($<line>.ast) if $<line>;

            make join ';', @v;
        }
        method text($/) { make '$_T ~= q{' ~ $/ ~ '}'; }
        method inline($/) { make $<code>.ast}
        method line($/) { make $<code>.ast}
        method code($/) {
            given ($<mode>) {
                when '' { make $0 }
                when .chars == 2 { make '$_T ~= ' ~ $0 ~ '' }
                default { make '$_T ~= %vars<html_escape>.(' ~ $0 ~ ')' }
            }
        }
        method start($/) { make ~$/}
        method line_start($/) { make ~$/}
        method end($/) { }
        method mode($/) { make ~$/}
        method leftover($/) { make '$_T ~= q{' ~ $/ ~ '};'; }
    }

    my $match = Template.parse($template, :actions(Template::Actions));
    die 'Cannot parse template' unless $match;

    my $code = $match.ast;

    return EVAL $code or die $_;
}

sub to_app is export {
    sub (%env) {
        my $path_info = %env<PATH_INFO>      || '/';
        my $method    = %env<REQUEST_METHOD> || 'GET';

        try {
            return http_error 'Not found', 404
              unless (my $m = %APP<routes>{$method})
              && (my $c = $m{$path_info});

            my $res = $c();
            return $res if $res ~~ Array;

            return [200, ['Content-Type' => 'text/html; charset=utf-8'], [$res]];

            CATCH {
                warn "System error: $_";
                return http_error 'System error';
            }
        }
    }
}
