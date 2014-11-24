use Test;

use Wee;

include_templates q:to/END/;
@@ simple.wee
Hi from <%= %vars<foo> %>
END

subtest {
    my $output = render('simple.wee', foo => 'bar');

    is $output, 'Hi from bar';
}, 'render simple text';

subtest {
    my $output = render(\'%= %vars<foo>', foo => 'bar');

    is $output, 'bar';
}, 'render inlined template';

done;
