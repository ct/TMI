# NAME

TMI - Slice and Dice weight values

# VERSION

Version 1.0

# SYNOPSIS

Take a list of weights, slice and dice those bad boys.

Assumes a MySQL database named "tmi" having a table called "weights" with two columns, an
AUTO\_INCREMENT weightsID and a float called weight.

# SUBROUTINES

## new()

    my $tmi = TMI->new(dbuser=>'user', dbpass=>'pass');

or

    my $tmi = TMI->new(dbuser=>'user', dbpass=>'pass', startrec=>100);

to start counting from day 100. dbuser and dbpass are mandatory.

## weights()

Returns an arrayref containing all of the weights in the selected range.

## totaldays()

Returns a value indicating how many days/records were pulled from the database.

## totaldeltas()

Returns a value indicating how many weight changes, which is totaldays - 1, since day 1 is a point, not a delta.

## firstweight()

Returns a value indicating first/earliest weight of values pulled.

## lastweight()

Returns a value indicating last/newest weight of values pulled.

## lastloss()

Returns a value indicating last days weight loss. If called with any true value as an argument,
it will wrap any positive deltas in an html span with bold red text.

    $last = $tmi->lastloss(1);

Would return 

    <span style="color:red; font-weight:bold;">+1</span>

If the lastloss value is +1.

## totalloss()

Returns a value indicating weight lost over the entire range of pulled values.

## percentloss()

Returns a value indicating weight lost over the entire range of pulled values as a
percentage of the earliest weight in the range.

## percentloss()

Returns a value indicating weight lost over the entire range of pulled values as a
percentage of the earliest weight in the range.

## avglosstotal()

Returns a value indicating average daily loss across entire range of pulled values.

## avglossrange()

Returns a value indicating average daily loss across a specific range of pulled values.

    $avg = $tmi->avglossrange(10);

Would give the average daily loss over the last ten days.

If no range is specified the range defaults to 14 days.

If the requested range is greater than the total number of records, all days averaged.

## weightdaysago()

Returns a value indicating recorded weight a specific number of days ago. If no argument is
specified a default of 14 days is used.

## daystovalue()

Returns a value indicating how many days it will take to reach a target weight.

    $days = $tmi->daystovalue($targetweight,$range);

If no targetweight is specified, an error will be thrown.

The $range argument specified a value for "using the average daily loss over the last $range days".
If this value is not supplied it will default to 14.

## daystodelta()

    $days = $tmi->daystodelta($targetweight,$range);

Returns a value indicating how many days it will take to reach a specified weight $targetweight
lower than the last/current weight.

If no targetweight is specified, an error will be thrown.

The $range argument specified a value for "using the average daily loss over the last $range days".
If this value is not supplied it will default to 14.

# AUTHOR

Chris Thompson, `<chris at cthompson.com>`

# BUGS

There are no bugs, only unrefined features.

# LICENSE AND COPYRIGHT

Use it, don't use it, whatever.
