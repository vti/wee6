module Wee;

use Wee::Routes;
use Wee::Template;

my %APP;
init;

sub init () is export {
    %APP = ();

    %APP<routes> = Wee::Routes.new;
    %APP<template> = Wee::Template.new;
}

sub include_templates ($templates) is export {
    for $templates.split(/^^\@\@\s+/).grep({$_ ne ""}) -> $include {
        my ($name, $content) = $include.split(/\n/, 2);

        %APP<includes>{$name} = $content.chomp;
    }
}

multi sub route ($method, $path, $handler) {
    my $ref = $handler ~~ Callable ?? $handler !! sub { $handler };

    %APP<routes>.add($path, :method($method), :cb($ref));
}

multi sub route ($method, Pair $pair) {
    route($method, $pair.key, $pair.value);
}

sub get  (|args) is export { route('GET',  |args) }
sub post (|args) is export { route('POST', |args) }

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

sub to_app is export {
    sub (%env) {
        my $path_info = %env<PATH_INFO>      || '/';
        my $method    = %env<REQUEST_METHOD> || 'GET';

        sub env is export { %env }
        sub content_type (Str $content_type) is export {
            %env<wee><content_type> = $content_type;
        }
        sub render ($name, *%vars) is export {
            my $template = $name ~~ Capture ?? ~$name !! %APP<includes>{$name}
              or die "Template not found";

            my $ref = $template ~~ Callable ?? $template !! %APP<template>.compile($template);
            %APP<includes>{$name} = $ref unless $ref ~~ \Str;

            %vars<html_escape> //= &html_escape;
            %vars<env> //= %env;
            return $ref.(%vars);
        }
        sub http_error ($message, $code = 500) is export {
            my $output = $message;
            try {
                $output = render($code, code => $code, message => $message);
            }

            return [$code, [], [$output]];
        }

        try {
            my $match = %APP<routes>.match($path_info, :$method);
            return http_error 'Not found', 404
              unless $match;

            my $res = $match.args<cb>();
            return $res if $res ~~ Array;

            %env<wee> = {};

            return [200, ['Content-Type' => %env<wee><content_type> || 'text/html; charset=utf-8'], [$res]];

            CATCH {
                warn "System error: $_";
                return http_error 'System error';
            }
        }
    }
}
