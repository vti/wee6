Wee6
===

The Perl6 PSGI-like framework.

```perl
use v6;

use lib 'lib';

use Wee;

post '/' => 'hi there';

get '/env' => {
    content_type 'text/plain';
    env.perl
};

get '/template' => { render 'index.html' };

get '/raw' => [200, [], ['Raw response']];

get '/500' => { die 'here' };

get '/file' => {
    content_type 'text/plain; charset=utf-8';

    slurp $?FILE
};

get '/redirect' => redirect '/';

get '/form' => { render 'form.html' };
post '/form' => {
    'Submitted. Good bye';
};

# Until =begin DATA is implemented
include_templates q:to/END/;
@@ index.html
<html>
    <body>
        <h1>Привет!</h1>
    </body>
</html>

@@ form.html
<form method="POST">
<input name="name" />
<input type="submit" />
</form>

@@ 500
Error <%= %vars<code> ~ ': ' ~ %vars<message> %>.

@@ 404
Not found!
END

my $app = to_app;

use HTTP::Easy::PSGI;
my $http = HTTP::Easy::PSGI.new(:port(8080));

$http.handle($app);
```
