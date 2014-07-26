###########################################
## Don't be fat and track it to make sure
###########################################
package TMI;
use 5.001;
use strict;
use Carp;

use DBI;
use List::Util qw(sum);
use Date::Calc qw(Today Add_Delta_Days);

=head1 NAME

TMI - Slice and Dice weight values

=cut

=head1 VERSION

Version 1.0

=cut


our $VERSION = '1.0';

=head1 SYNOPSIS

Take a list of weights, slice and dice those bad boys.

Assumes a MySQL database named "tmi" having a table called "weights" with two columns, an
AUTO_INCREMENT weightsID and a float called weight.

=head1 SUBROUTINES

=head2 new()

    my $tmi = TMI->new(dbuser=>'user', dbpass=>'pass');

or

    my $tmi = TMI->new(dbuser=>'user', dbpass=>'pass', startrec=>100);

to start counting from day 100. dbuser and dbpass are mandatory.

=cut

sub new {
    my $class = shift;
    my %conf  = @_;

    ## Get DB Credentials or punt
    $conf{"dsn"} //= "DBI:mysql:tmi";
    croak "dbuser not provided" unless defined $conf{"dbuser"};
    croak "dbpass not provided" unless defined $conf{"dbpass"};

    ## Allow specifying which day to start on, or assume day zero
    $conf{startrec} //= 0;

    ## arrayref for weights
    $conf{weights} = [];

    ## Grab weights from db
    my $dbh = DBI->connect("DBI:mysql:tmi", $conf{dbuser}, $conf{dbpass});
    my $sth = $dbh->prepare(
        "select weight from weights where weightID > $conf{startrec}");
    $sth->execute;
    while ( my ($weight) = $sth->fetchrow_array ) {
        push @{ $conf{weights} }, $weight;

    }
    $sth->finish;
    $dbh->disconnect;

    ## Return Blessed object
    return bless {%conf}, $class;
}

=head2 weights()

Returns an arrayref containing all of the weights in the selected range.

=cut

sub weights {
  my $self = shift;
  return $self->{weights};
}

=head2 totaldays()

Returns a value indicating how many days/records were pulled from the database.

=cut

sub totaldays {
  my $self = shift;
  return scalar( @{$self->{weights}} );
}

sub totaldeltas {
  my $self = shift;
  return $self->totaldays - 1;
}

=head2 totaldeltas()

Returns a value indicating how many weight changes, which is totaldays - 1, since day 1 is a point, not a delta.

=cut

=head2 firstweight()

Returns a value indicating first/earliest weight of values pulled.

=cut

sub firstweight {
  my $self = shift;
  return $self->{weights}->[0]
}

=head2 lastweight()

Returns a value indicating last/newest weight of values pulled.

=cut


sub lastweight {
  my $self = shift;
  return $self->{weights}->[$self->totaldays - 1];
}

=head2 lastloss()

Returns a value indicating last days weight loss. If called with any true value as an argument,
it will wrap any positive deltas in an html span with bold red text.

    $last = $tmi->lastloss(1);

Would return 

    <span style="color:red; font-weight:bold;">+1</span>

If the lastloss value is +1.

=cut

sub lastloss {
  my $self = shift;
  my $color = shift;
  my $loss = sprintf("%0.2f", $self->lastweight - $self->{weights}->[$self->totaldays - 2]);
  return defined $color ? 
	$loss > 0 ? "<span style=\"color:red\; font-weight:bold;\">+$loss</span>" : $loss :
        $loss ;
}

=head2 totalloss()

Returns a value indicating weight lost over the entire range of pulled values.

=cut

sub totalloss {
  my $self = shift;
  return (sprintf("%0.2f", $self->lastweight - $self->firstweight) * -1);
}

=head2 percentloss()

Returns a value indicating weight lost over the entire range of pulled values as a
percentage of the earliest weight in the range.

=cut

sub percentloss {
  my $self = shift;
  return (sprintf("%0.2f", $self->totalloss / $self->firstweight * 100));
}

=head2 avglosstotal()

Returns a value indicating average daily loss across entire range of pulled values.

=cut

sub avglosstotal {
  my $self = shift;
  return sprintf("%0.2f", $self->totalloss / $self->totaldeltas);
}

=head2 avglossrange()

Returns a value indicating average daily loss across a specific range of pulled values.

    $avg = $tmi->avglossrange(10);

Would give the average daily loss over the last ten days.

If no range is specified the range defaults to 14 days.

If the requested range is greater than the total number of records, all days averaged.

=cut

sub avglossrange {
  my $self = shift;
  my $range = shift // 14;
  if ($range > $self->totaldays) {
#     carp "Range specified ($range) greater than total records. Cropping to " . $self->totaldays;
     $range = $self->totaldays;
  }
  my $firstrecord = $self->totaldays - $range;

  return sprintf("%0.2f", ($self->lastweight - $self->{weights}->[$self->totaldays - $range]) / ($range -1) );
}

=head2 weightdaysago()

Returns a value indicating recorded weight a specific number of days ago. If no argument is
specified a default of 14 days is used.

=cut

sub weightdaysago {
  my $self = shift;
  my $delta = shift // 14;

  if ($delta > $self->totaldays) {
#     carp "Range specified ($range) greater than total records. Cropping to " . $self->totaldays;
     $delta = $self->totaldays;
  }

  return $self->{weights}->[$self->totaldays - $delta];

}

=head2 daystovalue()

Returns a value indicating how many days it will take to reach a target weight.

    $days = $tmi->daystovalue($targetweight,$range);

If no targetweight is specified, an error will be thrown.

The $range argument specified a value for "using the average daily loss over the last $range days".
If this value is not supplied it will default to 14.

=cut

sub daystovalue {
  my $self = shift;
  my $target = shift || croak "target value not specified for daystovalue, punting";

  my $range = shift // 14;

  return $self->daystodelta( $self->lastweight - $target, $range );
}

=head2 daystodelta()

    $days = $tmi->daystodelta($targetweight,$range);

Returns a value indicating how many days it will take to reach a specified weight $targetweight
lower than the last/current weight.

If no targetweight is specified, an error will be thrown.

The $range argument specified a value for "using the average daily loss over the last $range days".
If this value is not supplied it will default to 14.

=cut

sub daystodelta {
  my $self = shift;
  my $target = shift || croak "target value not specified for daystodelta, punting";

  my $range = shift // 14;

  my $date = (); 
  $date->{days} = int(($target / abs($self->avglossrange($range)))+0.5);
  my ($y,$m,$d) = Add_Delta_Days(Today,$date->{days} );

  $date->{date} = "$m/$d/$y";

  return $date;

}

=head1 AUTHOR

Chris Thompson, C<< <chris at cthompson.com> >>

=head1 BUGS

There are no bugs, only unrefined features.

=head1 LICENSE AND COPYRIGHT

Use it, don't use it, whatever.

=cut
1;    # End of TMI
