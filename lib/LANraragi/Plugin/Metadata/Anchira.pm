package LANraragi::Plugin::Metadata::Anchira;

use strict;
use warnings;

use File::Basename;

use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_plugin_logger);
use LANraragi::Utils::Archive qw(is_file_in_archive extract_file_from_archive);

use YAML::Syck qw(LoadFile);

sub plugin_info {

    return (
        name        => "Anchira",
        type        => "metadata",
        namespace   => "anchirayamlmeta",
        author      => "letrix (from siliconfeces/kskyamlmeta)",
        version     => "0.001",
        description => "Collects metadata either embedded into your archives from 'info.yaml' file or in the same folder with the name '{NAME_NOEXT}.yaml'.",
        icon        =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAKaUExURQAAAPrbofzcp/fYqPveruKxn8Jyhth6f/q7l//GjvDRmvraoNyLfPfIl//jjuPGjunEkOawg+OqcdargNefdOW7jcyhe758a+W2fd22ir1/auS7lo9WZO7Jq8SPbvfTudqndu/QtsWPafPVu7uQbO/VtuXAlYliSj4qH+O4kMqwp+OqjvDCqdKhg//GquG9rOfUx9q0jdGigOPGqvrv7+fVzs6qltO1oNrDtOPLuN22mtuxnPjYofrbpvrfqfvhqfXZpsOAe+7LlfjYnvfVnffcp+3Mm/TWoPbcqfrboMOLddGAct+6iOzIku7JkvPQmPHOmeO7kPLMq/TVnu3GlPPOk7qCa8J3a+O+ie3KkevEjea/jfDHodGslbaSduG2i+/Hje3Ch6tzZeLOterFjea/ie/Kj+C5iei/oaiJgY9jU+K3jd6ygOGzftyseZtgZOjEpOfEj9eugd20g+rEjNyzh/LLse7SyOi7p+q7m9irfNute9yresGKauC6oOG7jOfEjr2Xeceddt+2hu3GrvrYwvvWwfTGseK6hseVceW5gcmSbuXEqNqziNu0hq6LfKyDeN6xlO7Ir/3cxfzYwvPOtNapjdSne9use8mUb+C8ncuffd23jL+Sed64q/XNuPrVwPzZxPvVwPbOueO4oNmugMuZc9+xe+C6k8aUdvXXs9izjs+ljPDGsfrUv/rSvvXMttWph8mXgMyYcsOQbN63m//iy8+ki7mLetStl+3Cru7ArffMuee7puW3pMGPedOfcuvFq/zhyerGqdm1ldG2pdjAuevBrvTJteq9q4poV619Xc6ZcPbSus2ojd65i+/k4Ovg3+LPy+fV0e3e2tC7rdOfc9Koh+/k4uzf3+ze3vDk5O/e0////wHXBCoAAAA8dFJOUwAxl9n5+dmXMQma/v6aCQnBwQmamjH+/jGXl9nZ+fn5+dnZl5cx/v4xmpoJwcEJmv7+mgkxl9n5+dmXMTuv0Y4AAAABYktHRN1wZ7MhAAAAB3RJTUUH6AQUFR4ONSwmBAAAAQ9JREFUGNNjYAACRiZmFlY2dg4GCODk4raxtbN3cOTh5QPx+QWcnF1c3dw9PL28BYWAAsI+vn7+AYFBwSGhYeEiDAyiYhGRUX7RMbFx8QmJSeISDJLJKampaekZmVnZObl5+VIM0gWFRcUlpWXlFZVV1TW1MgyydfUNjU3NLa1t7R2dXd1yDPI9vX39EyZOmjxl6rTpM2YqMCjOmj1n7rz5CxYuWrxk6bLlSgzKK1auWr1m7bpF6zds3LR5iwqDqtrWbdt37Ny1e8/effsPqGswMGgePHT4yNFjx0+cPHX6jBbQpdo6Z8+dv3Dx0uUrV6/paoM8o6dvcP3GzVu37xgaGUP9a2JqZm5haWUNYgMArC9gd0Z89q4AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDQtMjBUMjE6MzA6MTMrMDA6MDA1MQn9AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTA0LTIwVDIxOjMwOjEzKzAwOjAwRGyxQQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNC0wNC0yMFQyMTozMDoxNCswMDowMNberhAAAAAASUVORK5CYII=",
        parameters => [ { type => "bool", desc => "Assume english" } ],
    );
}

sub get_tags {
    shift;
    my $lrr_info = shift;
    my ($assume_english) = @_;

    my $logger = get_plugin_logger();
    my $file   = $lrr_info->{file_path};

    my ( $name, $path, $suffix ) = fileparse( $lrr_info->{file_path}, qr/\.[^.]*/ );
    my $path_nearby_yaml = $path . $name . '.yaml';

    $path_in_archive = is_file_in_archive( $file, "info.yaml" );

    my $filepath;
    my $delete_after_parse;

    if ( -e $path_nearby_yaml ) {
        $filepath = $path_nearby_yaml;
        $logger->debug("Found file in the same folder at $filepath");
        $delete_after_parse = 0;
    } elsif ($path_in_archive) {
        $filepath = extract_file_from_archive( $file, $path_in_archive );
        $logger->debug("Found file in archive at $filepath");
        $delete_after_parse = 1;
    } else {
        return ( error => "No Anchira metadata file found in archive or in the same folder" );
    }

    my $parsed_data = LoadFile($filepath);

    my ( $tags, $title ) = tags_from_ksk_yaml( $parsed_data, $assume_english );

    if ($delete_after_parse) {
        unlink $filepath;
    }

    #Return tags
    $logger->info("Sending the following tags to LRR: $tags");
    if ($title) {
        $logger->info("Parsed title is $title");
        return ( tags => $tags, title => $title );
    } else {
        return ( tags => $tags );
    }
}

sub tags_from_ksk_yaml {
    my $hash           = $_[0];
    my $assume_english = $_[1];
    my @found_tags;
    my $logger = get_plugin_logger();

    my $title    = $hash->{"Title"};
    my $tags     = $hash->{"Tags"};
    my $parody   = $hash->{"Parody"};
    my $artists  = $hash->{"Artist"};
    my $magazine = $hash->{"Magazine"};
    my $url      = $hash->{"URL"};
    my $released = $hash->{"Released"};

    foreach my $tag (@$tags) {
        push( @found_tags, $tag );
    }
    foreach my $tag (@$artists) {
        push( @found_tags, "artist:" . $tag );
    }
    foreach my $tag (@$parody) {
        push( @found_tags, "series:" . $tag );
    }
    foreach my $tag (@$magazine) {
        push( @found_tags, "magazine:" . $tag );
    }
    if ($assume_english) {
        push( @found_tags, "language:english" );
    }

    push( @found_tags, "source:" . $url ) unless !$url;
    push( @found_tags, "date_added:" . $released ) unless !$released;

    #Done-o
    my $concat_tags = join( ", ", @found_tags );
    return ( $concat_tags, $title );

}

1;
