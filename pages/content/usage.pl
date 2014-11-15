{
    layout => 'sidebar',
    scripts => [ "/stc/common.js" ],
    title => '',
    content => do {
        open my $data, "<", "../usage.html";
        read_then_close($data);
    }
}
