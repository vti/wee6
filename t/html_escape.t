use Test;

use Wee;

subtest {
    my $output = html_escape('1');

    is $output, '1';
}, 'not escapes anything';

subtest {
    my $output = html_escape('<');

    is $output, '&lt;';
}, 'escapes <';

subtest {
    my $output = html_escape('>');

    is $output, '&gt;';
}, 'escapes >';

subtest {
    my $output = html_escape('"');

    is $output, '&quot;';
}, 'escapes "';

subtest {
    my $output = html_escape('&');

    is $output, '&amp;';
}, 'escapes &';

subtest {
    my $output = html_escape('1 > 2 & 3');

    is $output, '1 &gt; 2 &amp; 3';
}, 'escapes complex';

done;
