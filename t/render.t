use Test;

use Wee;

include_templates q:to/END/;
@@ simple.wee
Hi from template

@@ inline_vars.wee
Hi from <%= %vars<foo> %>

@@ inline_not_escaped_vars.wee
<%== %vars<foo> %>

@@ vars.wee
%= %vars<foo>

@@ complex.wee
<ul>
% for 1..3 -> $li {
<li><%= $li %></li>
% }
</ul>
END

subtest {
    my $output = render('simple.wee');

    is $output, "Hi from template\n";
}, 'render simple text';

subtest {
    my $output = render('inline_vars.wee', foo => 'bar');

    is $output, "Hi from bar\n";
}, 'render with inline vars';

subtest {
    my $output = render('inline_vars.wee', foo => '1 > 3');

    is $output, "Hi from 1 &gt; 3\n";
}, 'render with escaped inline vars';

subtest {
    my $output = render('inline_not_escaped_vars.wee', foo => '1 > 3');

    is $output, "1 > 3\n";
}, 'render with not escaped inline vars';

subtest {
    my $output = render('vars.wee', foo => 'bar');

    is $output, "bar";
}, 'render with vars';

subtest {
    my $output = render('complex.wee', foo => 'bar');

    ok $output ~~ m{'<ul>' \s+ '<li>1</li>' \s+ '<li>2</li>' \s+ '<li>3</li>' \s+ '</ul>'};
}, 'render complex code';

subtest {
    my $output1 = render('complex.wee', foo => 'bar');
    my $output2 = render('complex.wee', foo => 'bar');

    is $output1, $output2;
}, 'render template several times';

subtest {
    my $output = render(\'%= %vars<foo>', foo => 'bar');

    is $output, 'bar';
}, 'render inlined template';

done;
