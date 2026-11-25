# Match netrc's machine token and hostname, even on separate lines.
/^[[:space:]]*#/ { print; next }
{
    for (i = 1; i <= NF && $i !~ /^#/; i++) {
        if (machine && $i == old) {
            $i = new
            found = 1
        }
        machine = ($i == "machine")
    }
    print
}
END { if (!found) exit 1 }
