package Polycom::Contact::Directory;
use strict;
use warnings;
use utf8;

use IO::File;
use List::MoreUtils;
use XML::Simple;

use Polycom::Contact;

our $VERSION = 0.01;

######################################
# Overloaded Operators
######################################
use overload (
    '==' => sub { $_[0]->equals($_[1]) },
    '!=' => sub { !$_[0]->equals($_[1]) },
);

###################
# Constructor
###################
sub new
{
    my ($class, $file) = @_;

    my @contacts;
    if ($file)
    {
        my $xml = XMLin(
            $file,
            ForceArray => [ 'item_list', 'item' ],
            KeyAttr => []
        );

        @contacts = map {
            Polycom::Contact->new(
                first_name     => $_->{fn},
                last_name      => $_->{ln},
                contact        => $_->{ct},
                speed_index    => $_->{sd},
                label          => $_->{lb},
                ring_type      => $_->{rt},
                divert         => $_->{dc} || 0,
                auto_reject    => $_->{ar} || 0,
                auto_divert    => $_->{ad} || 0,
                buddy_watching => $_->{bw} || 0,
                buddy_block    => $_->{bb} || 0,
            );
        } (@{ $xml->{item_list}->[0]->{item} });
    }

    return bless {
        contacts => \@contacts,
    }, $class;
}

###################
# Public methods
###################

sub add
{
    my ($self, @contacts) = @_;

    push @{$self->{contacts}}, map
        {
            UNIVERSAL::isa($_, 'Polycom::Contact') ? $_ : Polycom::Contact->new(%{$_})
        } @contacts;
}

sub all
{
    return @{$_[0]->{contacts}};
}

sub search
{
    my ($self, $cond) = @_;
    return if !defined $cond || !ref $cond;

    my @results;
    foreach my $contact (@{$self->{contacts}})
    {
       if (List::MoreUtils::all { defined $cond->{$_} && $contact->{$_} eq $cond->{$_} } keys %{$cond})
       {
           push @results, $contact;
       }
    }  

    return @results;
}

sub count
{
    my ($self) = @_;
    return scalar(@{$self->{contacts}});
}

sub to_xml
{
    my ($self) = @_;
    
    my $xml =   "<directory>\n"
            .   " <item_list>\n";
    foreach my $contact ($self->all)
    {
        $xml .= "  <item>\n";
        $xml .= "   <fn>$contact->{first_name}</fn>\n"     if defined $contact->{first_name};
        $xml .= "   <ln>$contact->{last_name}</ln>\n"      if defined $contact->{last_name};
        $xml .= "   <ct>$contact->{contact}</ct>\n"        if defined $contact->{contact};
        $xml .= "   <sd>$contact->{speed_index}</sd>\n"    if defined $contact->{speed_index};
        $xml .= "   <lb>$contact->{label}</lb>\n"          if defined $contact->{label};
        $xml .= "   <rt>$contact->{ring_type}</rt>\n"      if defined $contact->{ring_type};
        $xml .= "   <dc>$contact->{divert}</dc>\n"         if defined $contact->{divert};
        $xml .= "   <ar>$contact->{auto_reject}</ar>\n"    if defined $contact->{auto_reject};
        $xml .= "   <ad>$contact->{auto_divert}</ad>\n"    if defined $contact->{auto_divert};
        $xml .= "   <bw>$contact->{buddy_watching}</bw>\n" if defined $contact->{buddy_watching};
        $xml .= "   <bb>$contact->{buddy_block}</bb>\n"    if defined $contact->{buddy_block};
        $xml .= "  </item>\n";
    }
    
    $xml .=     " </item_list>\n"
          .     '</directory>';
    
    return $xml;
}

sub save
{
    my ($self, $filename) = @_;

	my $fh = IO::File->new($filename, '>');
	$fh->binmode(':utf8');

	print $fh $self->to_xml;
}

sub is_valid
{
    my ($self) = @_;

    my %contact_num;
    my %speed_index;
    foreach my $contact (@{$self->{contacts}})
    {
        # Verify that all of the constituent contacts are valid
        if (!$contact->is_valid)
        {
            return;
        }

        # Verify that there are no duplicate contact values
        if (exists $contact_num{$contact->{contact}})
        {
            return;
        }
        $contact_num{$contact->{contact}} = 1;

        # Verify that there are no duplicate speed dial values
        if (exists $speed_index{$contact->{speed_index}})
        {
            return;
        }
        $speed_index{$contact->{speed_index}} = 1;
    }

    return 1;
}

sub equals
{
    my ($self, $other) = @_;
    
    # The are unequal if they contain different numbers of contacts
    return if $self->count != $other->count;
    
    for my $i (0 .. $self->count - 1)
    {
        if ($self->{contacts}->[$i] != $other->{contacts}->[$i])
        {
            return;
        }
    }
    
    return 1;
}

'Together. Great things happen.';

=head1 NAME

Polycom::Contact::Directory - Module for parsing, modifying, and creating Polycom VoIP phone local contact directory files.

=head1 SYNOPSIS

  use Polycom::Contact::Directory;

  # Load an existing contact directory file
  my $dir = Polycom::Contact::Directory->new('0004f21ac123-directory.xml');  

  # Add some contacts
  $dir->add(
    {   first_name => 'Jenny',
        last_name  => 'Xu',
        contact    => '2',
    },
    {   first_name => 'Jacky',
        last_name  => 'Cheng',
        contact    => '3',
    },
  );

  # Save the directory to an XML file suitable for being read by the phone
  $dir->save('0004f21ac123-directory.xml');

  # Iterate through all of the contacts 
  foreach my $contact ($dir->all)
  {
    # ...
  }

  # Find only those contacts whose last name is "Smith"
  my @smiths = $dir->search({ last_name => 'Smith' });


=head1 DESCRIPTION

This module parses Polycom VoIP phone local contact directory files, and can be used to read, modify, or create local contact directory files.

=head2

=over 4

=item I<Polycom::Contact::Directory>->new()

  # Create a new empty directory
  my $dir = Polycom::Contact::Directory->new();

  # Load a directory from a filename or file handle
  my $dir2 = Polycom::Contact::Directory->new('directory.xml');
  my $dir3 = Polycom::Contact::Directory->new(\*FILEHANDLE);

If you have already slurped the contents of a contact directory file into a scalar, you can also pass that scalar to I<new()> to parse those XML contents:

  my $xml = <<"END_XML";
    <directory>
     <item_list>
      <item>
       <fn>Bob</fn>
       <ct>1234</ct>
      </item>
     </item_list>
    </directory>
  END_XML

  my $dir = Polycom::Contact::Directory->new($xml);

=item I<$dir>->add(@contacts)

  $dir->add(
    {   first_name => 'Jenny',
        last_name  => 'Xu',
        contact    => '2',
        speed_index => 1,
        ring_type   => 5,
    },
    {   first_name => 'Jacky',
        last_name  => 'Cheng',
        contact    => '3',
        speed_index => 2,
        ring_type   => 10,
    },
  );

Adds the specified I<@contacts> contacts, if any, to the directory. I<@contacts> may be an array of hash references containing keys like "first_name", "last_name", and "contact", or it can be an array of C<Polycom::Contact> objects.

=item I<$directory>->all

  my @contacts = $dir->all;
  foreach my $contact (@contacts)
  {
    # ...
  }

Returns an array of all of the C<Polycom::Contact> objects in the contact directory.

=item I<$directory>->count

  my $num_contacts = $dir->count;

Returns the number of contacts in the directory.

=item I<$directory>->equals($directory2)

  if ($dir1->equals($dir2))
  {
    print "The contact directories are equal\n";
  }

Returns true if both contact directories are equal (i.e. they contain the same contacts).

Because the I<==> and I<!=> operators have also been overloaded for both C<Polycom::Contact> and C<Polycom::Contact::Directory> objects, it is equivalent to compare two contact directories using:

  if ($dir1 == $dir2)
  {
    print "The contact directories are equal\n";
  }

=item I<$directory>->is_valid

  if (!$dir->is_valid)
  {
    print "$dir is invalid.\n";
  }

Returns true if each contact has a contact number, there are no duplicate contact numbers, and there are no duplicate speed index numbers. Otherwise, it returns false.

=item I<$directory>->save($filename_or_file_handle)

  $dir->save('0004f21acabf-directory.xml');
  # or
  $dir->save(\*FILEHANDLE);

Writes the contents of the contact directory object to the specified file such that a phone should be able to read those contacts from the file if the file is placed on the phone's boot server.

=item I<$directory>->search($condition)

  my @smiths = $dir->search({ last_name => 'Smith' });

Returns an array of the contacts that match the specified condition. I<$condition> must be a hash reference whose keys are field names of C<Polycom::Contact> fields (e.g. first_name, last_name, contact, ring_type, etc). All of the specified conditions must hold in order for a contact to be present in the array returned.

=item I<$directory>->to_xml()

  my $xml = $directory->to_xml;

Returns the XML representation of the contact directory. It is exactly this XML representation that the I<save()> method writes to the local contact directory file.

=back

=head1 SEE ALSO

Polycom::Contact - Represents a contact in the local contact directory. Each Polycom::Contact::Directory contains zero or more Polycom::Contact objects.

=head1 AUTHOR

Zachary Blair, E<lt>zachary.blair@polycom.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Polycom Canada 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

