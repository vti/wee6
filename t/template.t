use Test;

use Wee::Template;

my $t = Wee::Template.new;

sub html_escape ($input is copy) {
    $input.trans:
        /'&'/  => '&amp;',
        /'"'/  => '&quot;',
        /'<'/  => '&lt;',
        /'>'/  => '&gt;',
        /\xA0/ => '&nbsp;',
        ;
}

my %default_vars = html_escape => &html_escape;

subtest {
    my $output = $t.compile('Hi from template').({%default_vars});

    is $output, 'Hi from template';
}, '$t.compile simple text';

subtest {
    my $output = $t.compile('Hi from <%= %vars<foo> %>').({%default_vars, foo => 'bar'});

    is $output, 'Hi from bar';
}, '$t.compile with inline vars';

subtest {
    my $output = $t.compile('Hi from <%= %vars<foo> %>').({%default_vars, foo => '1 > 3'});

    is $output, 'Hi from 1 &gt; 3';
}, '$t.compile with escaped inline vars';

subtest {
    my $output = $t.compile('<%== %vars<foo> %>').({%default_vars, foo => '1 > 3'});

    is $output, '1 > 3';
}, '$t.compile with not escaped inline vars';

subtest {
    my $output = $t.compile('%= %vars<foo>').({%default_vars, foo => 'bar'});

    is $output, "bar";
}, 'compile with vars';

subtest {
    my $output = $t.compile(q:to/END/).({%default_vars, foo => 'bar'});
<ul>
% for 1 .. 3 -> $li {
    <li><%= $li %></li>
% }
</ul>
END

    ok $output ~~ m{'<ul>' \s+ '<li>1</li>' \s+ '<li>2</li>' \s+ '<li>3</li>' \s+ '</ul>'};
}, 'compile complex code';

done;
