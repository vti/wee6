use Test;

use Wee::Routes;

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/');

    my $match = $routes.match('/');

    ok $match;
}, 'match root';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo');

    my $match = $routes.match('/foo');

    ok $match;
}, 'match simple route';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo/bar');

    my $match = $routes.match('/foo/bar');

    ok $match;
}, 'match simple multiple route';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo', :some('arg'));

    my $match = $routes.match('/foo');

    ok $match;
    is $match.path, '/foo';
    is $match.args<some>, 'arg';
}, 'match simple route with args';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo');

    my $match = $routes.match('/another');

    ok !$match;
}, 'not match when wrong path';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo', :method('POST'));

    my $match = $routes.match('/foo', :method('GET'));

    ok !$match;
}, 'not match when wrong method';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/foo');

    my $match = $routes.match('/foo', :method('GET'));

    ok $match;
}, 'match when no method';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/:foo');

    my $match = $routes.match('/bar');

    ok $match;
    is $match.captures<foo>, 'bar';
}, 'match with capture';

subtest {
    my $routes = Wee::Routes.new;

    $routes.add('/:foo/path');

    my $match = $routes.match('/bar/path');

    ok $match;
    is $match.captures<foo>, 'bar';
}, 'match with capture and path';

done;
