package Polycom::Contact;
use strict;
use warnings;
use base qw(Class::Accessor);

our $VERSION = 0.01;

use overload (
    '==' => sub { !$_[0]->diff($_[1]) },
    '!=' => sub { scalar $_[0]->diff($_[1]) },
    '""' => sub {
        my $name = join ' ', grep {defined} 
            ($_[0]->{first_name}, $_[0]->{last_name});
        return join ' at ', grep {$_} ($name, $_[0]->{contact});
    },
);

Polycom::Contact->mk_accessors(
    qw(first_name last_name contact speed_index label ring_type
       divert auto_reject auto_divert buddy_watching buddy_block)
);

###################
# Constructors
###################
sub new
{
    my ($class, %args) = @_;

    my $self = {
        first_name     => $args{first_name},
        last_name      => $args{last_name},
        contact        => $args{contact},
        speed_index    => $args{speed_index},
        label          => $args{label},
        ring_type      => $args{ring_type},
        divert         => $args{divert} || 0,
        auto_reject    => $args{auto_reject} || 0,
        auto_divert    => $args{auto_divert} || 0,
        buddy_watching => $args{buddy_watching} || 0,
        buddy_block    => $args{buddy_block} || 0,
    };

    if (!defined $self->{contact} || $self->{contact} eq '')
    {
        warn "No 'contact' attribute specified";
    } 

    return bless $self, $class;
}

###################
# Public Methods
###################
sub is_valid
{
    my ($self) = @_;

    if ($self->{contact})
    {
        return 1;
    }
    return;
}

sub diff
{
    my ($self, $other) = @_;

    # Map each contact attribute to a "nice" name (e.g. first_name => "First Name")
    my %LABELS = (
        first_name     => 'First Name',
        last_name      => 'Last Name',
        contact        => 'Number',
        speed_index    => 'Speed Index',
        label          => 'Label',
        ring_type      => 'Ring Type',
        divert         => 'Divert',
        auto_reject    => 'Auto Reject',
        auto_divert    => 'Auto Divert',
        buddy_watching => 'Buddy Watch',
        buddy_block    => 'Buddy Block',
    );

    my @nonMatchingFields;
    while (my ($attr, $label) = each %LABELS)
    {
        my $mine   = defined $self->{$attr}  ? $self->{$attr}  : 0;
        my $theirs = defined $other->{$attr} ? $other->{$attr} : 0;
        
        # Normalize boolean fields
        if ($attr eq 'auto_reject' || $attr eq 'auto_divert'
            || $attr eq 'buddy_watching')
        {
            $mine   =~ s/Enabled/1/i;    
            $theirs =~ s/Enabled/1/i;    
            $mine   =~ s/Disabled//i;    
            $theirs =~ s/Disabled//i;    
        }
        
        if ($mine ne $theirs)
        {
            push(@nonMatchingFields, $attr);
        }
    }

    return @nonMatchingFields;
}

=head1 NAME

Polycom::Contact - Class representing local contact directory contacts of Polycom VoIP phones.

=head1 SYNOPSIS

  use Polycom::Contact;

  # Create a new contact
  my $contact = Polycom::Contact->new(
      first_name => 'Bob',
      last_name  => 'Smith',
      contact    => '1234',
  );

  # The contact can be interpolated in strings
  # Prints: "The contact is: Bob Smith at 1234"
  print "The contact is: $contact\n";

  # The contact can also be compared with other contacts
  my $otherContact = Polycom::Contact->new(first_name => 'Jimmy', contact => '5678');
  if ($otherContact != $contact)
  {
    print "$otherContact is not the same as $contact\n";
  }

  # Or, of course, you can simply query the contact's fields
  my $first_name = $contact->first_name;
  my $last_name  = $contact->last_name;

=head1 DESCRIPTION

The Polycom::Contact class is used to represent a contact in a Polycom VoIP phone's local contact directory. This class is intended to be used with Polycom::Contact::Directory, which parses entire contact directory files, extracting the contacts, and enabling you to read or modify them.

=head2 Methods

=over 4

=item Polycom::Contact->new()

  use Polycom::Contact;
  my $contact = Polycom::Contact->new(first_name => 'Bob', contact => 1234);

Returns a newly created C<Polycom::Contact> object.

In all, each C<Polycom::Contact> object can have the following fields:
=over
=item first_name
=item last_name
=item contact
=item speed_index
=item label
=item ring_type
=item divert
=item auto_reject
=item auto_divert
=item buddy_watching
=item buddy_block
=back

Of those fields, the I<contact> field is the only required field; without a unique I<contact> field, the phone will not load the contact.

=item I<$contact>->is_valid

  if (!$contact->is_valid)
  {
      print "$contact is invalid.\n";
  }

Returns I<undef> if the contact is invalid (i.e. it has no I<contact> value specified), or 1 otherwise.

=item I<$contact>->diff(I<$contact2>)

  my @differences = $contact1->diff($contact2);

Returns an array of contact field names that do not match (e.g. "First Name", "Speed Dial").

=back

=head1 SEE ALSO

Polycom::Contact::Directory - A closely related module that parses the XML-based local contact directory file used by Polycom VoIP phones, and can be used to read, modify, or create contacts in the file. 

=head1 AUTHOR

Zachary Blair, E<lt>zachary.blair@polycom.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Polycom Canada 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

'Together. Great things happen.';
