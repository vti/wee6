use Test;

use Wee;

include_templates q:to/END/;
@@ 513
Error <%= %vars<code> %>: <%= %vars<message> %>.
END

subtest {
    my $output = http_error('error');

    is_deeply $output, [500, [], ['error']];
}, 'wraps error';

subtest {
    my $output = http_error('error', 503);

    is_deeply $output, [503, [], ['error']];
}, 'wraps error with custom code';

subtest {
    my $output = http_error('error', 513);

    is_deeply $output, [513, [], ['Error 513: error.']];
}, 'renders template if available';

done;
