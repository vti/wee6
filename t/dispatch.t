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

#subtest 'dispatch to template' => sub {
#    init;
#
#    include_templates q::to/END/
#        @@ template.wee
#        Hi from template
#    END
#
#    get('/', sub { render('template.wee') });
#
#    my $res = to_app->();
#    is $res.[0], 200;
#    is_deeply $res.[2], ['Hi from template'];
#};
#
#subtest 'throw when template not found' => sub {
#    init;
#
#    get('/', sub { render('unknown.wee') });
#
#    my $res = to_app->();
#    is $res.[0], 500;
#    is_deeply $res.[2], ['System error'];
#};

done;
