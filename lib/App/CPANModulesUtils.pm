package App::CPANModulesUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

$SPEC{gen_acme_cpanmodules_module_from_acme_cpanlists_list} = {
    v => 1.1,
    summary => 'Generate an Acme::CPANModules module file from an Acme::CPANLists module list',
    args => {
        input_module => {
            schema => 'perl::modname*',
            req => 1,
            pos => 0,
            description => <<'_',

"Acme::CPANLists::" will be prepended if module name does not begin with it.

_
        },
        input_list_index => {
            schema => 'nonnegint*',
            cmdline_aliases => {n=>{}},
            description => <<'_',

Required if the Acme::CPANLists module contains more than one module list.

_
        },
        output_module => {
            schema => 'perl::modname*',
            description => <<'_',

"Acme::CPANModules::" will be prepended if module name does not begin with it.

Will default to the Acme::CPANLists module name, with CPANLists replaced by
CPANModules.

_
        },
        output_file => {
            schema => 'filename*',
            description => <<'_',

will default to "lib/Acme/CPANModules/<YourModuleName>.pm

_
            #cmdline_aliases => {o=>{}},
        },
        overwrite => {
            schema => 'true*',
            cmdline_aliases => {O=>{}},
        },
    },
};
sub gen_acme_cpanmodules_module_from_acme_cpanlists_list {
    require Data::Dump;
    require File::Path;
    require File::Slurper;

    my %args = @_;

    my $input_module = $args{input_module};
    $input_module = "Acme::CPANLists::$input_module"
        unless $input_module =~ /\AAcme::CPANLists::/;

    my $output_module = $args{output_module} // do {
        (my $val = $input_module) =~ s/CPANLists/CPANModules/;
        $val;
    };
    log_trace "output_module=$output_module";
    $output_module = "Acme::CPANModules::$input_module"
        unless $output_module =~ /\AAcme::CPANModules::/;

    my $output_file = $args{output_file} // do {
        (my $val = "lib/$output_module.pm") =~ s!::!/!g;
        $val;
    };

    my $idx = $args{input_list_index};
    (my $input_module_pm = "$input_module.pm") =~ s!::!/!g;
    require $input_module_pm;
    my $module_lists = \@{"$input_module\::Module_Lists"};
    @$module_lists or return [412, "$input_module doesn't contain any module list"];
    if (@$module_lists > 1) {
        defined $idx or return [400, "Please specify input_list_index because $input_module contains more than one module list"];
        $idx < @$module_lists or return [400, "There is no module list #$idx in $input_module"];
    }
    $idx //= 0;

    if (-f $output_file) {
        $args{overwrite} or return [412, "Output file $output_file already exists, specify another file or --overwrite"];
    } else {
        if ($output_file =~ m!/.!) {
            (my $dir = $output_file) =~ s!(.+)/.+!$1!;
            File::Path::make_path($dir);
        }
    }

    (my $prog = $0) =~ s!.+/!!;

    my $output = join(
        "",

        "# This file was first automatically generated by ", $prog, " on ", (scalar localtime), " from module list in ", $input_module, " version ", (${"$input_module\::VERSION"} // "dev"), ".\n",
        "\n",

        "package $output_module;\n",
        "\n",

        "# DATE\n",
        "# VERSION\n",
        "\n",

        "our \$LIST = ", Data::Dump::dump($module_lists->[$idx]), ";\n",
        "\n",

        "1;\n",
        "# ABSTRACT: ", ($module_lists->[$idx]{summary} // "(no summary)"), "\n",
        "\n",
    );

    log_info "Writing output to $output_file ...";
    File::Slurper::write_text($output_file, $output);
    [200];
}

$SPEC{acme_cpanmodules_for} = {
    v => 1.1,
    summary => 'List Acme::CPANModules distributions that mention specified modules',
    description => <<'_',

This utility consults <prog:lcpan> (local indexed CPAN mirror) to check if there
are <pm:Acme::CPANModules> distributions that mention specified modules. This is
done by checking the presence of a dependency with the relationship
`x_mentions`.

_
    args => {
        modules => {
            schema => ['array*', of=>'perl::modname*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },

};
sub acme_cpanmodules_for {
    require App::lcpan::Call;

    my %args = @_;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ["rdeps", "--rel", "x_mentions", @{ $args{modules} }],
    );

    return $res unless $res->[0] == 200;

    return [200, "OK", [grep {/\AAcme-CPANModules/}
                            map {$_->{dist}} @{ $res->[2] }]];
}

1;
#ABSTRACT: Command-line utilities related to Acme::CPANModules

=head1 SYNOPSIS


=head1 DESCRIPTION

This distribution includes the following command-line utilities related to
L<Acme::CPANModules>:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<Acme::CPANModules>
