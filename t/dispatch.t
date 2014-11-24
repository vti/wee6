use Test;

use Wee;

subtest {
    init;

    get('/', 'Hi there');

    my $res = to_app.({});
    is $res.[0], 200;
    is_deeply $res.[2], ['Hi there'];
}, 'dispatch to simple text';

subtest {
    init;

    get('/', [500, [], ['Error']]);

    my $res = to_app.({});
    is $res.[0], 500;
    is_deeply $res.[2], ['Error'];
}, 'dispatch to array reference';

subtest {
    init;

    get('/', sub { 'Hi there' });

    my $res = to_app.({});
    is $res.[0], 200;
    is_deeply $res.[2], ['Hi there'];
}, 'dispatch to code reference';

subtest {
    init;

    my $res = to_app.({});
    is $res.[0], 404;
    is_deeply $res.[2], ['Not found'];
}, 'return 404 when no route found';

subtest {
    init;

    get('/', sub { die 'error' });

    my $res = to_app.({});
    is $res.[0], 500;
    is_deeply $res.[2], ['System error'];
}, 'catch error';

subtest {
    init;

    include_templates q:to/END/;
    @@ template.wee
    Hi from template
    END

    get '/', { render('template.wee') };

    my $res = to_app.({});
    is $res.[0], 200;
    is_deeply $res.[2], ['Hi from template'];
}, 'renders template';

subtest {
    init;

    get '/', { render(\'Hi from template') };

    my $res = to_app.({});
    is $res.[0], 200;
    is_deeply $res.[2], ['Hi from template'];
}, 'renders inlined template';

subtest {
    init;

    get '/', { render('unknown.wee') };

    my $res = to_app.({});
    is $res.[0], 500;
    is_deeply $res.[2], ['System error'];
}, 'throw when template not found';

subtest {
    init;

    get '/', { http_error 'System error' };

    my $res = to_app.({});
    is $res.[0], 500;
    is_deeply $res.[2], ['System error'];
}, 'returns error';

subtest {
    init;

    get '/', { http_error 'System error', 503 };

    my $res = to_app.({});
    is $res.[0], 503;
    is_deeply $res.[2], ['System error'];
}, 'returns error with custom status';

subtest {
    init;

    include_templates q:to/END/;
    @@ 513
    Error <%= %vars<code> %>: <%= %vars<message> %>.
    END

    get '/', { http_error 'System error', 513 };

    my $res = to_app.({});
    is_deeply $res.[2], ['Error 513: System error.'];
}, 'renders error when template available';

done;
