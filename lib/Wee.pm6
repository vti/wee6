module Wee;

use Wee::Template;

my %APP;
init;

sub init () is export {
    %APP = ();

    %APP<template> = Wee::Template.new;
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

sub get  (|args) is export { route('GET',  |args) }
sub post (|args) is export { route('POST', |args) }

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

    my $ref = $template ~~ Callable ?? $template !! %APP<template>.compile($template);
    %APP<includes>{$name} = $ref unless $ref ~~ \Str;

    %vars<html_escape> //= &html_escape;
    return $ref.(%vars);
}

sub to_app is export {
    sub (%env) {
        my $path_info = %env<PATH_INFO>      || '/';
        my $method    = %env<REQUEST_METHOD> || 'GET';

        try {
            return http_error 'Not found', 404
              unless (my $m = %APP<routes>{$method})
              && (my $c = $m{$path_info});

            %env<wee> = {};

            sub env is export { %env }
            sub content_type (Str $content_type) is export {
                %env<wee><content_type> = $content_type;
            }

            my $res = $c();
            return $res if $res ~~ Array;

            return [200, ['Content-Type' => %env<wee><content_type> || 'text/html; charset=utf-8'], [$res]];

            CATCH {
                warn "System error: $_";
                return http_error 'System error';
            }
        }
    }
}
