use v6;

use lib 'lib';

use Wee;

get '/', 'hi there';

get '/env', {
    content_type 'text/plain';
    env.perl
};

get '/index.html', { render 'index.html' };

get '/raw', [200, [], ['Raw response']];

get '/500', { die 'here' };

get '/file', slurp $?FILE;

get '/redirect', redirect '/';

get '/form', { render 'form.html' };
post '/form', {
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
OOOOOPS!
END

my $app = to_app;

use HTTP::Easy::PSGI;
my $http = HTTP::Easy::PSGI.new(:port(8080));

$http.handle($app);
