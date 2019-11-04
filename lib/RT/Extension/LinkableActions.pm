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
    local $Storable::Deparse = 1; 

    my $attribute_key = 'RTLinkableAction-'.$args{'Ticket'}->Id ."-".$args{'Transaction'}->Id;
    if ( $args{'Ticket'}->FirstAttribute( $attribute_key ) ) {
        my ($ret, $msg) = $args{'Ticket'}->SetAttribute(
            Name     => $attribute_key,
            Content  => $args{'Sub'}
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
            Content => $args{'Sub'}
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
