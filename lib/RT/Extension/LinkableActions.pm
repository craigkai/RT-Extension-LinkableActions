use strict;
use warnings;
package RT::Extension::LinkableActions;

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

    my $code = $args{'NoAuth'} ? q[
        my $Ticket       = RT::Ticket->new( RT->SystemUser );
        my $Transaction  = RT::Transaction->new( RT->SystemUser );

        $Ticket->Load(].$args{'Ticket'}->Id.');'
        .q[
        $Transaction->Load(].$args{'Transaction'}->Id.q[);

    ] : q[
        my $Ticket       = RT::Ticket->new( $session{'CurrentUser'} );
        my $Transaction  = RT::Transaction->new( $session{'CurrentUser'} );

        $Ticket->Load(].$args{'Ticket'}->Id.');'
        .q[
        $Transaction->Load(].$args{'Transaction'}->Id.q[);

    ];
    $code .= $args{'Sub'};

    my $name_key = $args{'Name'};
    $name_key =~ s/\s/_/mg;

    my $attribute_key = 'RTLinkableAction-'.$args{'Ticket'}->Id ."-".$args{'Transaction'}->Id."-$name_key";
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

![Demo](https://files.ceal.dev/linkable-actions-demo.gif)

=begin html

<img src="./static/images/linkable-actions-demo.gif" alt="Demo"></img>

=end html

=head1 RT VERSION

Works with RT 5.0

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
            Ticket        => $Ticket,
            Transaction   => $Transaction,
            Sub           => $sub,
            Name          => 'Issue is resolved',
            NoAuth        => 0
        );
    }

Where the "Name" key will be the name displayed as the text content of the resulting anchor tag.

**WARNING** Adding the `NoAuth` flag means that anyone can execute action as the RT->SystemUser.
=cut

=head2 Todo

* Clean-up template method call

* Add a `CompileCheck` call on template update to check if code is valid in $sub.

=cut

=head1 AUTHOR

Craig Kaiser

=cut

1;
