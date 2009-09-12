#!/usr/bin/perl -w

#    dancer.pl is an helper script for the great module Dancer.
#    Copyright (C) 2009  Sébastien Deseille (sebastien.deseille@gmail.com)

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use File::Spec::Functions;
use Getopt::Long;
use CGI qw/:standard/;

my $app_name;
my $app_path;
my $app_dir;
my $app_engine;
my $static_index;
my $main_yaml_config;
my $main_config_options;
my $views_dir;
my $layouts_dir;
my $dev_yaml_config;
my $dev_config_options;
my $main_css_file;
my $help=0;
my $template=0;

GetOptions("h|help"       => \$help,
           "n|app_name=s" => \$app_name,
           "p|app_path:s" => \$app_path,
           "template"     => \$template
           );

# Before make anything read this help
if ($help) {
    help();
}

# It's good to check if application name is defined
if (!defined $app_name) {
    print "  __________________________\n";
    print "\n ! Missing Application name ! \n";
    print "  __________________________\n\n";
    help();
}


#DEB Variables Initialisation-----------------------#
print "Create application : ",$app_name,"\n";

$app_path=curdir() unless defined $app_path;
print "Application location : $app_path \n";

$app_dir=catdir($app_path,$app_name);
print "Application directory : $app_dir \n";

$app_engine=catfile($app_dir,$app_name.".pl");
print "Application engine : $app_engine \n";

$views_dir=catfile($app_dir,'views');
$layouts_dir=catfile($views_dir,'layouts');
$static_index=catfile($app_dir,'public','index.html');

$main_yaml_config=catfile($app_dir,'config.yml');
$main_config_options={'layout' => "'main'",
                      'logger' => "'file'",
                     };

$dev_yaml_config=catfile($app_dir,'environments','development.yml');
$dev_config_options={'port' => 3000,
                     'log'  => "'debug'",
                    };

$main_css_file=catfile($app_dir,'public','css','style.css');

my @directorytree=('environments',
                   'logs',
                   'public' => ['css','errors','images' => ['jpg','png','gif']],
                   'views' => ['layouts'],
                   ); 

my $view_hello=<<'ENDME'
<h1>Hello <% params.name %>!</h1>

Welcome to the hello action <% params.name %>
ENDME
;

my $view_index=<<'ENDME'
<h1>Welcome to the dance floor!</h1>

<p>
I'm a standalone web application, written in pure Perl. 
</p>

<img src="/images/dancers.jpg" alt="dancers" />

<p>
<% if message %>
<% message %>
<% else %>
<em>Dance is beautiful, make your webapp move smoothly!</em>
<% end %>
</p>
ENDME
;

my $layout_main=<<'ENDME'
<html>
<head>
<title>Hello There!</title>
  <link rel='stylesheet' href='/css/style.css' type='text/css' media="screen, projection">
</head>
<body>

<div id="container">

    <% if note %>
    <div style="border: 1px solid #447; background-color: #dde; padding: 1em;">
    <% note %>
    </div>
    <% end %>

<% content %>

  <div id="footer">
    Powered by <a href="http://github.com/sukria/Dancer/">Dancer</a>
  </div>
</div>

</body>
</html>
ENDME
;

my $error_code={404 => 'Not Found',
                500 => 'Internal Server Error',
                503 => 'Service Unavailable',
               };

#FIN Variables Initialisation-----------------------#


#DEB Main program-----------------------#
if ( ! -d $app_dir ) {
    mkdir $app_dir or die "mkdir $app_dir error : $!\n";
    moonwalk($app_dir,\&build_dancefloor,@directorytree);
    write_app($app_engine);
    build_yaml_configfile($main_yaml_config,$main_config_options);
    build_yaml_configfile($dev_yaml_config,$dev_config_options);
    build_css_file($main_css_file);
    build_index($static_index,$app_name);
    build_error_page($error_code);
}
else {
    print "Directory already used !! \n";
    print "Choose another application name or application path !! \n";
    exit;
}
#FIN Main program-----------------------#


#--------------------Usefull Functions-----------------------#

sub build_dancefloor {
    my $floor=catdir(split(/,/,shift));
    if ( ! $template && ($floor =~ /views/) ){
        return;
    }
    print "+ Creating $floor\n";
    mkdir $floor or die "mkdir $floor error : $!\n";
}

sub moonwalk {
    my ($container,$builder,@items) = @_;
    my $branch;

    foreach my $item (@items) {
        if ( ref $item eq '') {
            $branch="$container,$item";
            $builder->($branch);
            #print "$branch\n";
        }
        elsif ( ref $item eq 'ARRAY' ) {
            moonwalk($branch,$builder,@{$item});
        }
    } 
}

sub build_index {
    my ($static_index,$title)=@_;
    open my $index_handle, ">", "$static_index"
        or die "Error occured with file $static_index : $! \n";

    print "+ Creating $static_index\n";
    print $index_handle start_html(-title => $title,
                                   -style => {'src'=>'/css/style.css'},),
                        h2("Welcome in your Web Application"),
                        h2("$title"),
                        end_html();
    close $index_handle;
}

sub build_error_page {
    my $error_codes=shift;
    foreach my $error_code (keys %$error_codes) {
        my $errorpage=catfile($app_dir,'public','errors',$error_code.'.html');
        open my $errorpage_handle, ">", "$errorpage"
            or die "Error occured with file $errorpage : $! \n";
        
        print "+ Creating $errorpage\n";
        print $errorpage_handle start_html(-title => $error_code),
                            h2("Error $error_code : ",$error_codes->{$error_code}),
                            end_html();
        close $errorpage_handle;
    }
}

sub build_yaml_configfile {
    my ($yaml_configfile,$yaml_options)=@_;
    open my $config_handle, ">", "$yaml_configfile"
        or die "Error occured with file $yaml_configfile : $! \n";
    print "+ Creating $yaml_configfile\n";
    foreach my $key (keys %{$yaml_options}) {
        print $config_handle "$key: ".$yaml_options->{$key}."\n";
    }
    close $config_handle;
}

sub help {
    print <<'ENDUSAGE';
Welcome to the helper ->dancer<-
    
Usage:
    dancer [options] <appname>
    
    options are following :
    -h, --help            : print what you are currently reading
    -n, --app_name=STRING : the name of your application
    -p, --app_path=STRING : the path where to create your application
                            (current directory by default if not specified)
    --template            : create a views directory and make sure
                            Template is installed.
                            
dancer comes with ABSOLUTELY NO WARRANTY
ENDUSAGE
exit 0;
}

sub write_view {
    my $view_model=shift;
    my $view_content=shift;
    open my $view_handle, ">", "$view_model"
        or die "Error occured with file $view_model : $! \n";
    print $view_handle $view_content;
    print "+ Creating $view_model\n";
    close $view_handle;
}

sub write_layout {
    my $layout_model=shift;
    my $layout_content=shift;
    open my $layout_handle, ">", "$layout_model"
        or die "Error occured with file $layout_model : $! \n";
    print $layout_handle $layout_content;
    print "+ Creating $layout_model\n";
    close $layout_handle;
}

sub write_app {
    my $app_engine=shift;
    if ($template) {
        write_template_app($app_engine);
        write_view(catfile($views_dir,'hello.tt'),"$view_hello");
        write_view(catfile($views_dir,'index.tt'),"$view_index");
        write_layout(catfile($layouts_dir,'main.tt'),"$layout_main");
    }
    else {
        write_static_app($app_engine);
    }
}

sub write_static_app {
    my $app_engine=shift;
    open my $app_handle, ">", "$app_engine"
        or die "Error occured with file $app_engine : $! \n";
    print $app_handle <<'ENDME';

#!/usr/bin/perl

use Dancer;
use Template;

get '/' => sub {
    send_file '/index.html';
};    

before sub {
    var note => "I ARE IN TEH BEFOR FILTERZ";
    debug "in the before filter";
    mime_type html => 'text/html';
};

dance;
  
ENDME
    close $app_handle;
}

sub write_template_app {
    my $app_engine=shift;
    open my $app_handle, ">", "$app_engine"
        or die "Error occured with file $app_engine : $! \n";
    print $app_handle <<'ENDME';
#!/usr/bin/perl

use Dancer;
use Template;

before sub {
    var note => "I ARE IN TEH BEFOR FILTERZ";
    debug "in the before filter";
#    request->path_info('/foo/oversee')
};

get '/foo/*' => sub {
    my ($match) = splat; # ('bar/baz')
    debug "je suis dans /foo";
   
    use Data::Dumper;

    "note: '".vars->{note}."'\n<BR>".
    "match: $match\n<BR>".
    "request: ".Dumper(request);
};

# for testing Perl errors
get '/error' => sub {
    template();   
};

get '/' => sub {
    debug "welcome to the home";
    template 'index', {note => vars->{note}};
};

get '/hello/:name' => sub {
    template 'hello';
};

get '/page/:slug' => sub {
    template 'index' => {
        message => 'This is the page '.params->{slug},    
    };
};

post '/new' => sub {
    "creating new entry: ".params->{name};
};

get '/say/:word' => sub {
    if (params->{word} =~ /^\d+$/) {
        pass and return false;
    }
    "I say a word: '".params->{word}."'";
};

get '/download/*.*' => sub { 
    my ($file, $ext) = splat;
    "Downloading $file.$ext";
};

get '/say/:number' => sub {
    pass if (params->{number} == 42); # this is buggy :)
    "I say a number: '".params->{number}."'";
};

# this is the trash route
get r('/(.*)') => sub {
    my ($trash) = splat;
    status 'not_found';
    "got to trash: $trash";
};

dance;

ENDME
    close $app_handle;
}


sub build_css_file {
    my $css_file=shift;
    open my $css_handle, ">", "$css_file"
        or die "Error occured with file $css_file : $! \n";
    print $css_handle <<'ENDME';
    
body {
    font-family: sans-serif;
    background-color: #fff;
    color: #000;
}

h1, h2, h3 {
    color: #444;
    border-bottom: 1px solid #449;
}

img {
    border: 1px solid #ddd;
    padding: 1px;
    margin: 1em;
}

#container {
    margin: auto;
    width:700px;
}

#footer {
    margin-top: 2em;
    font-size: 10px;
    color: #aaa;
    border-top: 1px solid #aaa;
}
ENDME
    print "+ Creating $css_file\n";
    close $css_handle;    
}

__END__

=pod 

=head1 NAME

dancer.pl 

=head1 DESCRIPTION

->dancer.pl<- is an helper script for providing a bootstraping method for 
creating new applications with the great module Dancer.

Dancer is here to provide the simpliest way for writing a web application.

It can be use to write light-weight web services or small standalone web
applications.

If you want to start quickly with Dancer, ->dancer.pl<- is made for you. 

=head1 USAGE

dancer [options] <appname>


options are following :

=over

=item -h, --help            : print what you are currently reading
=item -n, --app_name=STRING : the name of your application
=item -p, --app_path=STRING : the path where to create your application
                            (current directory by default if not specified)

=item --template            : create a views directory and make sure
                            Template is installed.

=back

=head1 EXAMPLE

This is a possible webapp created with ->dancer.pl<- :

dancer.pl -n=webapp -p=c:\tmp --template

Model example is : Dancer\example\webapp.pl
Create application : webapp
Application location : c:\tmp
Application directory : C:\tmp\webapp
Application engine : C:\tmp\webapp\webapp.pl
+ Creating C:\tmp\webapp\environments
+ Creating C:\tmp\webapp\logs
+ Creating C:\tmp\webapp\public
+ Creating C:\tmp\webapp\public\css
+ Creating C:\tmp\webapp\public\errors
+ Creating C:\tmp\webapp\public\images
+ Creating C:\tmp\webapp\public\images\jpg
+ Creating C:\tmp\webapp\public\images\png
+ Creating C:\tmp\webapp\public\images\gif
+ Creating C:\tmp\webapp\views
+ Creating C:\tmp\webapp\views\layouts
+ Creating C:\tmp\webapp\views\hello.tt
+ Creating C:\tmp\webapp\views\index.tt
+ Creating C:\tmp\webapp\views\layouts\main.tt
+ Creating C:\tmp\webapp\config.yml
+ Creating C:\tmp\webapp\environments\development.yml
+ Creating C:\tmp\webapp\public\css\style.css
+ Creating C:\tmp\webapp\public\index.html
+ Creating C:\tmp\webapp\public\errors\503.html
+ Creating C:\tmp\webapp\public\errors\500.html
+ Creating C:\tmp\webapp\public\errors\404.html

=head1 AUTHOR

This script has been written by Sebastien Deseille <sebastien.deseille@gmail.com>

=head1 SOURCE CODE

The source code for this script is hosted on GitHub
L<http://github.com/sdeseille/Dancer>

=head1 DEPENDENCIES

->dancer.pl<- depends on the following modules:

The following modules are mandatory (->dancer.pl<- cannot run without them)

=over

=item L<CGI>

=item L<File::Spec>

=item L<Template>

=back


=head1 LICENSE

Copyright 2009 Sébastien Deseille

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO
Dancer Module on CPAN : http://search.cpan.org/dist/Dancer/
see L<http://github.com/sukria/Dancer> to contribute.

The concept behind this module comes from the Sinatra ruby project, 
see L<http://www.sinatrarb.com> for details.

=cut
