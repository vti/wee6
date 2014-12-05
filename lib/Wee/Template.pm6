module Wee::Template;

grammar Wee::Template::Grammar {
    regex TOP {
        ^ <chunk>* <leftover> $
    }
    regex chunk      { <text> [ <inline> | <line> ] }
    regex text       { .*?}
    regex code       { <mode> \h* (.*?)}
    regex line       { ^^ <line_start> <code> \s* [ \n | $ ] }
    regex inline     { <start> <code> \s* <end> }
    token line_start { '%' }
    token start      { '<%' }
    token end        { '%>' }
    token mode       { \= ** 0..2 }
    regex leftover   { .* }
}

class Wee::Template::Actions {
    method TOP($/) {
        my $code = 'sub (%vars) {my $_T;';

        my @chunks;
        for $<chunk>.list -> $c {
            @chunks.push($c.ast);
        }

        $code ~= join ';', @chunks, $<leftover>.ast;
        $code ~= '$_T;}';
        #warn $code;

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

class Wee::Template {
    method compile ($template) {
        my $match = Wee::Template::Grammar.parse($template, :actions(Wee::Template::Actions));
        die 'Cannot parse template' unless $match;

        my $code = $match.ast;

        return EVAL $code or die 'Cannot compile template: ' ~ $!;
    }
}
