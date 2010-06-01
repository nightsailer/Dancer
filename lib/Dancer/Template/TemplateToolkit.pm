package Dancer::Template::TemplateToolkit;

use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';
use Encode qw(encode_utf8);

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    my ($self) = @_;

    die "Template is needed by Dancer::Template::TemplateToolkit"
      unless Dancer::ModuleLoader->load('Template');

    my $tt_config = {
        ANYCASE   => 1,
        ABSOLUTE  => 1,
        %{$self->config},
    };

    my $start_tag = $self->config->{start_tag} || '<%';
    my $stop_tag  = $self->config->{stop_tag}  || $self->config->{end_tag} || '%>';

    # FIXME looks like if I set START/END tags to TT's defaults, it goes crazy
    # so I only change them if their value is different
    $tt_config->{START_TAG} = $start_tag if $start_tag ne '[%';
    $tt_config->{END_TAG}   = $stop_tag  if $stop_tag  ne '%]';

    $tt_config->{INCLUDE_PATH} = setting('views');

    $_engine = Template->new(%$tt_config);
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;
    die "'$template' is not a regular file"
      if !ref($template) && (!-f $template);

    my $content = "";
    $_engine->process($template, $tokens, \$content) or die $_engine->error;
    $content = encode_utf8($content) if $self->config->{encode_utf8};
    return $content;
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::TemplateToolkit - Template Toolkit wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template> module.

This template engine is recomended for production purposes, but depends on the
Template module.

In order to use this engine, use the template setting:

    template: template_toolkit

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Note that by default,  Dancer configures the Template::Toolkit engine to use 
<% %> brackets instead of its default [% %] brackets.  This can be changed
within your config file - for example:

    template: template_toolkit
    engines:
        template_toolkit:
            start_tag: '[%'
            stop_tag: '%]'

Note if your template is utf8 encode, you should apply this setting:

    template: template_toolkit
    engines:
        template_toolkit:
            start_tag: '[%'
            stop_tag: '%]'
            ENCODING: 'utf8'
            encode_utf8: 1

This will render page correctly and work around for  "Wide character in print at ..." warnings.


=head1 SEE ALSO

L<Dancer>, L<Template>

=head1 AUTHOR

This module has been written by Alexis Sukrieh

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
