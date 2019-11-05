use strict;
use warnings;
package RT::Extension::LinkableActions;

use B::Deparse;
use Data::Dumper;
$Data::Dumper::Deparse = 1;

our $VERSION = '0.01';

sub NewLinkAction {
    my $self = shift;
    my %args = (
        Ticket      => undef,
        Transaction => undef,
        Name        => undef,
        Sub         => undef,
        @_
    );

    my $code = q[
        my $Ticket       = RT::Ticket->new( $session{'CurrentUser'} );
        my $Transaction  = RT::Transaction->new( $session{'CurrentUser'} );

        $Ticket->Load(].$args{'Ticket'}->Id.');'
        .q[
        $Transaction->Load(].$args{'Transaction'}->Id.q[);

    ];
    $code .= $args{'Sub'};

    my $attribute_key = 'RTLinkableAction-'.$args{'Ticket'}->Id ."-".$args{'Transaction'}->Id;
    if ( $args{'Ticket'}->FirstAttribute( $attribute_key ) ) {
        my ($ret, $msg) = $args{'Ticket'}->SetAttribute(
            Name     => $attribute_key,
            Content  => $code
        );
        if ( $ret ) {
            RT::Logger->debug("Updating existing linked action attribute for $args{Name}");
        }
        else {
            RT::Logger->error("Could not update attribute for linked action $args{Name}: $msg");
        }
    }
    else {
        my ($ret, $msg) = $args{'Ticket'}->AddAttribute(
            Name    => $attribute_key,
            Content => $code
        );
        if ( $ret ) {
            RT::Logger->debug("Creating linked action attribute for $args{Name}");
        }
        else {
            RT::Logger->error("Could not add attribute for linked action $args{Name}: $msg");
        }
    }
    my $link;
    if ( $args{'NoAuth'} ) {
        $link = "<a href='".RT->Config->Get("WebURL")."NoAuth/Login.html?id=".$args{'Ticket'}->id."&RTLinkableAction=$attribute_key"."'>$args{'Name'}</a>";
    }
    else{
        $link  = "<a href='".RT->Config->Get("WebURL")."Ticket/Display.html?id=".$args{'Ticket'}->id."&RTLinkableAction=$attribute_key"."'>$args{'Name'}</a>";
    }

    return $link;
}

sub CompileCheck {
    my $self = shift;
    my $code = shift;

    return return (0, $self->loc("Provide CODE arg for compile check")) if !defined($code);

    do {
        no strict 'vars';
        eval "sub { $code \n }";
    };
    if ( $@ ) {
        my $error = $@;
        return (0, $self->loc("Couldn't compile linked action codeblock '[_2]': [_3]", $code, $error));
    }
    return (1, 'Success');
}
=head1 NAME

RT-Extension-LinkableActions - Create clickable links in emails that when clicked perform an action in RT.

=head1 DESCRIPTION

Like RT::Scrips that fire on click.

=head1 RT VERSION

Works with RT 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::LinkableActions');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

This extension uses a custom method call from templates to generate a link that will perform a action on click.
This method needs to be provided with the C<$Ticket> and C<$Transaction> objects from the template. You then pass
a string of the code you want executed. The example template below has a linked action that will resolve the ticket:

    Subject: {$Ticket->Subject}
    Content-Type: text/html

    {
        my $sub = q {
            my ($ret, $msg) = $Ticket->SetStatus('resolved');
            RT::Logger->error($msg) unless $ret;
        };
        $OUT = RT::Extension::LinkableActions->NewLinkAction(
            Ticket => $Ticket,
            Transaction => $Transaction,
            Sub => $sub,
            Name => 'Click ME'
        );
    }

Where the "Name" key will be the name displayed as the text content of the resulting anchor tag.

=cut

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-LinkableActions@rt.cpan.org">bug-RT-Extension-LinkableActions@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LinkableActions">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-LinkableActions@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LinkableActions

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Best Practical LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
