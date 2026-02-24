{
  name = "tempe";
  desc = "cd into a new temporary directory";
  usage = "tempe [SUBDIR]";
  type = "function";
  body = ''
    set temp_dir (mktemp -d)
    cd $temp_dir
    chmod -R 0700 .

    if test (count $argv) -eq 1
        mkdir -p $argv[1]
        cd $argv[1]
        chmod -R 0700 .
    end
  '';
}
