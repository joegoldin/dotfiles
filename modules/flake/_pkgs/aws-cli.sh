#!/usr/bin/env bash
# `aws`, re-running `aws login` when the console session has expired.
#
# Shadows awscli2 on PATH rather than living as a fish function, so it applies
# to every shell, script and agent tool call - the fish function it replaced
# was invisible to anything that wasn't an interactive fish prompt.
#
# @placeholders@ are substituted at eval time (see default.nix); the real CLI is
# always reached by absolute store path, so this can never recurse into itself.

unset PYTHONPATH

real=@awscli@/bin/aws
date=@coreutils@/bin/date
sha256sum=@coreutils@/bin/sha256sum
timeout=@coreutils@/bin/timeout
awk=@gawk@/bin/awk
sed=@gnused@/bin/sed
cut=@coreutils@/bin/cut
tr=@coreutils@/bin/tr
head=@coreutils@/bin/head
uname=@coreutils@/bin/uname

# Every branch that can't reason about the situation falls through to the bare
# binary intact, so the wrapper can only ever add a login, never change a command.
if [ $# -eq 0 ] || [ "${AWS_AUTOLOGIN:-}" = 0 ] || [ -n "${AWS_ACCESS_KEY_ID:-}" ]; then
  exec "$real" "$@"
fi

# `aws login` is a browser flow, so it only makes sense where a browser can be
# opened. This is true under agent tool calls (they inherit the desktop session)
# and false in CI, cron and plain SSH, where it would only burn the timeout.
if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && [ "$("$uname" -s)" != Darwin ]; then
  exec "$real" "$@"
fi

case " $* " in
  *" --version "* | *" --help "*) exec "$real" "$@" ;;
esac

# Walk argv for the subcommand and an explicit --profile, stepping over the
# global flags that take a value so their argument isn't mistaken for either one.
valued=(--profile --region --output --query --endpoint-url --ca-bundle
  --color --cli-read-timeout --cli-connect-timeout --cli-binary-format
  --cli-error-format)
args=("$@")
profile=""
subcmd=""
wants_help=0
i=0
while [ $i -lt ${#args[@]} ]; do
  arg=${args[$i]}
  case $arg in
    --profile=*)
      profile=${arg#--profile=}
      ;;
    *)
      is_valued=0
      for v in "${valued[@]}"; do
        if [ "$arg" = "$v" ]; then
          is_valued=1
          break
        fi
      done
      if [ $is_valued -eq 1 ]; then
        i=$((i + 1))
        if [ "$arg" = --profile ]; then
          profile=${args[$i]:-}
        fi
      elif [ "${arg#-}" = "$arg" ]; then
        if [ -z "$subcmd" ]; then
          subcmd=$arg
        fi
        # `help` as a bare word is the CLI's own help form (`aws s3 help`),
        # which needs no credentials at any depth.
        if [ "$arg" = help ]; then
          wants_help=1
        fi
      fi
      ;;
  esac
  i=$((i + 1))
done

if [ $wants_help -eq 1 ]; then
  exec "$real" "$@"
fi

# login/logout/configure manage credentials themselves.
case $subcmd in
  "" | login | logout | configure | sso) exec "$real" "$@" ;;
esac

if [ -z "$profile" ]; then
  profile=${AWS_PROFILE:-default}
fi

config_file=${AWS_CONFIG_FILE:-$HOME/.aws/config}
if [ ! -r "$config_file" ]; then
  exec "$real" "$@"
fi

# Read one key out of one section of the ini-ish aws config.
config_value() {
  # shellcheck disable=SC2016  # $0/$1 below are awk's fields, not the shell's
  "$awk" -v want="$1" -v key="$2" '
    {
      line = $0
      sub(/^[ \t]+/, "", line)
      sub(/[ \t]+$/, "", line)
    }
    line ~ /^\[/ { insec = (line == want); next }
    !insec { next }
    index(line, key) == 1 {
      rest = substr(line, length(key) + 1)
      if (rest ~ /^[ \t]*=/) {
        sub(/^[ \t]*=[ \t]*/, "", rest)
        sub(/[ \t].*$/, "", rest)
        found = rest
      }
    }
    END { print found }
  ' "$config_file"
}

# Find the login_session this profile ultimately resolves to, following
# source_profile up the chain. A profile that reaches no login_session isn't
# console-login based (SSO, static keys, saml2aws) - leave it alone.
target=$profile
session=""
session_profile=""
hops=0
while [ $hops -lt 5 ]; do
  if [ "$target" = default ]; then
    want="[default]"
  else
    want="[profile $target]"
  fi

  session=$(config_value "$want" login_session)
  if [ -n "$session" ]; then
    session_profile=$target
    break
  fi

  source_profile=$(config_value "$want" source_profile)
  # The self-referential source_profile in this config would otherwise spin.
  if [ -z "$source_profile" ] || [ "$source_profile" = "$target" ]; then
    break
  fi
  target=$source_profile
  hops=$((hops + 1))
done

if [ -z "$session" ]; then
  exec "$real" "$@"
fi

# Credentials live in <cache dir>/<sha256 of the login_session arn>.json.
cache_dir=${AWS_LOGIN_CACHE_DIRECTORY:-$HOME/.aws/login/cache}
digest=$(printf '%s' "$session" | "$sha256sum" | "$cut" -d' ' -f1)
cache_file=$cache_dir/$digest.json

if [ -r "$cache_file" ]; then
  expires_at=$("$sed" -n 's/.*"expiresAt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cache_file" | "$head" -n1)
  # Fixed-width ISO-8601 UTC, so digits-only compares as an integer.
  stamp=$(printf '%s' "$expires_at" | "$tr" -cd '0-9' | "$cut" -c1-14)
  now=$("$date" -u +%Y%m%d%H%M%S)
  if [ ${#stamp} -eq 14 ] && [ "$now" -lt "$stamp" ]; then
    exec "$real" "$@"
  fi
fi

# Cached credentials are stale, but the refresh token may still be good - this
# call is what exercises it. Silent when it works, so the ordinary hourly
# credential rollover stays invisible.
if "$real" sts get-caller-identity --profile "$profile" >/dev/null 2>&1; then
  exec "$real" "$@"
fi

timeout_secs=${AWS_AUTOLOGIN_TIMEOUT:-300}

echo "aws: session for profile '$session_profile' has expired - running 'aws login'" >&2

# Log in against the profile the session actually lives on, so the config
# rewrite is a no-op instead of stamping login_session onto a profile that only
# inherited it. stdout is folded into stderr so a login triggered inside
# `x=$(aws ...)` can't leak browser chatter into the capture.
"$timeout" --foreground "$timeout_secs" "$real" login --profile "$session_profile" >&2
rc=$?

if [ $rc -ne 0 ]; then
  if [ $rc -eq 124 ]; then
    echo "aws: login timed out after $timeout_secs seconds - command not run" >&2
  else
    echo "aws: login failed (exit $rc) - command not run" >&2
  fi
  exit $rc
fi

exec "$real" "$@"
