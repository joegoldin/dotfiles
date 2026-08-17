{
  name = "aws";
  desc = "aws CLI, re-running `aws login` when the console session has expired";
  function = ''
    # Only wrap interactive use - scripts, cron jobs and anything without a
    # human attached keep hitting the bare binary. Every branch below that
    # can't reason about the situation falls through to `command aws` intact,
    # so the wrapper can only ever add a login, never change a command.
    if not status is-interactive; or test (count $argv) -eq 0
        command aws $argv
        return $status
    end

    if test "$AWS_AUTOLOGIN" = 0; or set -q AWS_ACCESS_KEY_ID
        command aws $argv
        return $status
    end

    if contains -- --version $argv; or contains -- --help $argv
        command aws $argv
        return $status
    end

    # Walk argv for the subcommand and an explicit --profile, stepping over the
    # global flags that take a value so their argument isn't mistaken for
    # either one.
    set -l valued --profile --region --output --query --endpoint-url --ca-bundle \
        --color --cli-read-timeout --cli-connect-timeout --cli-binary-format \
        --cli-error-format
    set -l profile
    set -l subcmd
    set -l wants_help 0
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        if string match -q -- '--profile=*' $arg
            set profile (string replace -- '--profile=' "" $arg)
        else if contains -- $arg $valued
            set i (math $i + 1)
            if test "$arg" = --profile
                set profile $argv[$i]
            end
        else if not string match -q -- '-*' $arg
            if test -z "$subcmd"
                set subcmd $arg
            end
            # `help` as a bare word is the CLI's own help form (`aws s3 help`),
            # which needs no credentials at any depth.
            if test "$arg" = help
                set wants_help 1
            end
        end
        set i (math $i + 1)
    end

    # login/logout/configure manage credentials themselves.
    if test $wants_help -eq 1
        command aws $argv
        return $status
    end
    if test -z "$subcmd"; or contains -- $subcmd login logout configure sso
        command aws $argv
        return $status
    end

    if test -z "$profile"
        set profile $AWS_PROFILE
    end
    if test -z "$profile"
        set profile default
    end

    set -l config_file $AWS_CONFIG_FILE
    if test -z "$config_file"
        set config_file $HOME/.aws/config
    end
    if not test -r "$config_file"
        command aws $argv
        return $status
    end
    read -lz config_blob <"$config_file"
    set -l config_lines (string split \n -- $config_blob)

    # Find the login_session this profile ultimately resolves to, following
    # source_profile up the chain. A profile that reaches no login_session
    # isn't console-login based (SSO, static keys, saml2aws) - leave it alone.
    set -l target $profile
    set -l session
    set -l session_profile
    set -l hops 0
    while test $hops -lt 5
        set -l want "[profile $target]"
        if test "$target" = default
            set want "[default]"
        end
        set -l in_section 0
        set -l source_profile
        set session
        for line in $config_lines
            set -l trimmed (string trim -- $line)
            if string match -q -- '[*' $trimmed
                set in_section 0
                if test "$trimmed" = "$want"
                    set in_section 1
                end
                continue
            end
            if test $in_section -eq 0
                continue
            end
            set -l hit (string match -r '^login_session\s*=\s*(\S+)' -- $trimmed)
            if test (count $hit) -ge 2
                set session $hit[2]
            end
            set hit (string match -r '^source_profile\s*=\s*(\S+)' -- $trimmed)
            if test (count $hit) -ge 2
                set source_profile $hit[2]
            end
        end
        if test -n "$session"
            set session_profile $target
            break
        end
        # The self-referential source_profile in this config would otherwise spin.
        if test -z "$source_profile"; or test "$source_profile" = "$target"
            break
        end
        set target $source_profile
        set hops (math $hops + 1)
    end

    if test -z "$session"
        command aws $argv
        return $status
    end

    # Credentials live in <cache dir>/<sha256 of the login_session arn>.json.
    set -l cache_dir $AWS_LOGIN_CACHE_DIRECTORY
    if test -z "$cache_dir"
        set cache_dir $HOME/.aws/login/cache
    end
    set -l digest
    if command -q sha256sum
        set digest (printf '%s' $session | sha256sum | string split -f1 " ")
    else if command -q shasum
        set digest (printf '%s' $session | shasum -a 256 | string split -f1 " ")
    end

    set -l fresh 0
    if test -n "$digest"; and test -r "$cache_dir/$digest.json"
        read -lz token_blob <"$cache_dir/$digest.json"
        set -l hit (string match -r '"expiresAt"\s*:\s*"([^"]+)"' -- $token_blob)
        if test (count $hit) -ge 2
            # Fixed-width ISO-8601 UTC, so digits-only compares as an integer.
            set -l expires_at (string sub -l 14 -- (string replace -ra '[^0-9]' "" -- $hit[2]))
            set -l now (date -u +%Y%m%d%H%M%S)
            if test (string length -- $expires_at) -eq 14; and test $now -lt $expires_at
                set fresh 1
            end
        end
    end

    if test $fresh -eq 1
        command aws $argv
        return $status
    end

    # Cached credentials are stale, but the refresh token may still be good -
    # this call is what exercises it. Silent when it works, so the ordinary
    # hourly credential rollover stays invisible.
    if command aws sts get-caller-identity --profile $profile >/dev/null 2>&1
        command aws $argv
        return $status
    end

    set -l timeout_secs $AWS_AUTOLOGIN_TIMEOUT
    if test -z "$timeout_secs"
        set timeout_secs 300
    end

    echo "aws: session for profile '$session_profile' has expired - running 'aws login'" >&2

    # Log in against the profile the session actually lives on, so the config
    # rewrite is a no-op instead of stamping login_session onto a profile that
    # only inherited it. stdout is folded into stderr so a login triggered
    # inside `set x (aws ...)` can't leak browser chatter into the capture.
    set -l aws_bin (command --search aws)
    if command -q timeout; and test -n "$aws_bin"
        command timeout --foreground $timeout_secs $aws_bin login --profile $session_profile >&2
    else
        command aws login --profile $session_profile >&2
    end
    set -l rc $status

    if test $rc -ne 0
        if test $rc -eq 124
            echo "aws: login timed out after $timeout_secs seconds - command not run" >&2
        else
            echo "aws: login failed (exit $rc) - command not run" >&2
        end
        return $rc
    end

    command aws $argv
    return $status
  '';
}
