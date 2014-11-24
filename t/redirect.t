use Test;

use Wee;

subtest {
    my $res = redirect('/foo');
    is_deeply $res, [302, [Location => '/foo'], ['']];
}, 'build correct redirect response';

subtest {
    my $res = redirect('/foo', 301);
    is_deeply $res, [301, [Location => '/foo'], ['']];
}, 'build correct redirect response with custom code';

done;
