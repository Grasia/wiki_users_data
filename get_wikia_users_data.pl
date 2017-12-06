#!/usr/bin/perl

use utf8;
use feature 'say';
use warnings;
use diagnostics;
use strict;

use open ':encoding(UTF-8)';

use LWP::UserAgent;
use JSON;
use LWP::ConnCache;
use Data::Dumper;
use HTTP::Status qw(:constants :is status_message);
use IO::Handle;

# Define wiki to download
my $wiki_url = 'http://zelda.wikia.com';
#~ if (@ARGV < 1) {
        #~ print "Please, write the wiki domain (FQDN) you want to get the dump from (eg. es.lagunanegra.wikia.com)\n";
        #~ $wiki_url = <STDIN>;
        #~ chomp($wiki_url);
#~ } else {
        #~ $wiki_url = $ARGV[0];
#~ }



# browser agent
my $br = LWP::UserAgent->new;
$br->timeout(15);
#$br->conn_cache(LWP::ConnCache->new());
$br->agent("Mozilla/5.0");
$br->requests_redirectable(['POST', 'HEAD', 'GET']);


# listUsers API
my $listUsers_post_endpoint = 'index.php?' . 'action=ajax&rs=ListusersAjax::axShowUsers';
my $listUsers_url = "$wiki_url/$listUsers_post_endpoint";


# csv variables
my $csv_columns = 'user_id, edits_no, is_bot';
my $csv_fh;
my $output_filename;


# one argument: ($filename) => the file name for the file to create and open
sub open_output_file {
    my ($filename) = @_;
    my $encoding = ":encoding(UTF-8)";
    my $filehandle = undef;
    my $create_if_not_exists = not -e $filename;
    open ($filehandle, " >> $encoding", $filename) or die "Error trying to write on $filename: $!\n";
    autoflush $filehandle 1;
    print $filehandle "$csv_columns\n" if $create_if_not_exists;
    return $filehandle;
}


my $entries_per_page = "10";

# order of arguments = ($loop)
sub request_all_users {
    my ($loop) = @_;
    my @form_data = [
        groups => "all,bot,bureaucrat,rollback,sysop,threadmoderator,authenticated,bot-global,content-reviewer,council,fandom-editor,global-discussions-moderator,helper,restricted-login,restricted-login-exempt,reviewer,staff,util,vanguard,voldev,vstf,",
        username => "",
        edits => 1,
        limit => 10,
        offset => "0",
        loop => $loop, # simulate user behaviour
        order => "username:asc"
    ];

    #~ my $res = $br->post($listUsers_url, 'Content-Type' => 'application/json', Content => @form_data);
    my $res = $br->post($listUsers_url, @form_data);

    if (not $res->is_success) {
        #~ if ($res->code == HTTP_INTERNAL_SERVER_ERROR) {
            #~ say STDERR "Received 500 Internal Server Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            #~ sleep 10;
            #~ return request_all_users($loop);
        #~ } elsif (res->code == 503) {
            #~ say STDERR "Received 503 Service Unavailable Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            #~ sleep 10;
            #~ return request_all_users($loop);
        #~ } else {
            die $res->status_line.' when posting to Special:ListUsers querying for all users.';
        #~ }
    }

    my $raw_users_content = $res->decoded_content();
    #~ say $res->decoded_content();
    my $json_res = decode_json($raw_users_content);
    #~ print Dumper($json_res);
    my @users = $json_res->{'aaData'};
    print Dumper(@users);
    say (scalar @users);
    die;
    my $edits, my $is_bot, my $username;
    foreach my $user ( @users) {
        $user->[0][0] =~ /\/wiki\/User:(\w*)/;
        $username = $1;
        $is_bot = $user->[0][1] =~ /bot|bot-global/;
        $edits = $user->[0][2];

        say "$username, $edits, $is_bot";

    }
    die('foo');
}

# To fill $csv_columns => 'user_id, edits_no, is_bot';

# arguments = ($fh, $filename)
#   $fh: filehandle for the output csv
#   $filename: filename for the output csv
#~ sub print_wiki_to_csv {
    #~ my ($fh, $filename) = @_;

    #~ say "\n ---> Printing info for wiki $wikia_id into $filename .....";
    #~ print $fh "$user_id, $edits_no, $is_bot \n";

#~ }


#### Starts main(): #####

# creating CSV files handler for writing
#~ $csv_fh = open_output_file($output_filename);
say "Getting user data for wiki: $wiki_url...";
say $listUsers_url;
request_all_users(5);


close($csv_fh)
