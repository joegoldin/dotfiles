{
  name = "ghreview";
  desc = "Wrapper for gh-pr-review with auto-detection and code context";
  examples = [
    { cmd = "ghreview"; desc = "View reviews for current PR"; }
    { cmd = "ghreview --pretty"; desc = "Pretty-print as markdown"; }
    { cmd = "ghreview --raw"; desc = "Raw JSON output"; }
    { cmd = "ghreview --no-code"; desc = "Skip source code context"; }
    { cmd = "ghreview threads list"; desc = "List review threads"; }
  ];
  flags = [
    {
      name = "--raw";
      short = "-r";
      desc = "Output raw JSON without formatting";
      bool = true;
    }
    {
      name = "--no-code";
      short = "-n";
      desc = "Skip enriching output with source code context";
      bool = true;
    }
    {
      name = "--pretty";
      short = "-p";
      desc = "Pretty-print as readable markdown";
      bool = true;
    }
  ];
  fish = ''
    set -l with_code true
    if set -q _flag_no_code
      set with_code false
    end

    set -l pass_args $argv

    # Default to 'review view' if no subcommand given
    if test (count $pass_args) -eq 0
      set pass_args review view
    end

    set -l extra_args

    # Auto-detect repo unless -R already provided
    if not contains -- -R $pass_args
      set -l repo (gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
      if test -z "$repo"
        echo "Error: Could not detect repository. Use -R owner/repo" >&2
        exit 1
      end
      set extra_args -R $repo
    end

    # Auto-detect PR unless --pr already provided
    if not contains -- --pr $pass_args
      set -l pr_number (gh pr view --json number -q .number 2>/dev/null)
      if test -z "$pr_number"
        echo "Error: Could not detect PR. Checkout a branch with an associated PR" >&2
        exit 1
      end
      set extra_args $extra_args --pr $pr_number
    end

    # Run command to temp file for pipeline processing
    set -l tmpfile (mktemp)
    gh pr-review $pass_args $extra_args > $tmpfile

    # Detect output type: "reviews" (review view), "threads" (threads list), or "other"
    set -l output_type (jq -r 'if type == "object" and .reviews then "reviews" else if type == "array" and length > 0 and (.[0] | has("threadId")) then "threads" else "other" end end' $tmpfile)

    # Enrich with source code context if --code
    if $with_code; and test "$output_type" != other
      set -l ctxfile (mktemp)
      echo -n > $ctxfile

      # Extract path:line pairs depending on output type
      if test "$output_type" = reviews
        set -l locs (jq -r '[.reviews[]?.comments[]? | select(.path and .line) | "\(.path):\(.line)"] | unique[]' $tmpfile)
      else
        set -l locs (jq -r '[.[]? | select(.path and .line) | "\(.path):\(.line)"] | unique[]' $tmpfile)
      end

      for loc in $locs
        set -l parts (string split ':' -- $loc)
        set -l file $parts[1]
        set -l line_num $parts[2]
        if test -f "$file"
          set -l ctx_start (math "max(1, $line_num - 3)")
          set -l ctx_end (math "$line_num + 3")
          sed -n "$ctx_start,$ctx_end"p "$file" | awk -v n=$ctx_start '{printf "%d: %s\n", NR+n-1, $0}' | jq -Rs --arg key "$loc" '{($key): .}' >> $ctxfile
        end
      end

      set -l ctxlookup (mktemp)
      jq -s 'add // {}' $ctxfile > $ctxlookup

      if test "$output_type" = reviews
        jq --slurpfile ctx $ctxlookup '.reviews |= [.[] | if .comments then .comments |= [.[] | if .path and .line then . + {code_context: ($ctx[0]["\(.path):\(.line)"] // null)} else . end] else . end]' $tmpfile > "$tmpfile.tmp"
      else
        jq --slurpfile ctx $ctxlookup '[.[] | if .path and .line then . + {code_context: ($ctx[0]["\(.path):\(.line)"] // null)} else . end]' $tmpfile > "$tmpfile.tmp"
      end
      mv "$tmpfile.tmp" $tmpfile
      rm -f $ctxfile $ctxlookup
    end

    # Output
    if set -q _flag_pretty; and test "$output_type" = reviews
      jq -r '
        [.reviews[]? | select((.body and (.body | length > 0)) or (.comments and (.comments | length > 0)))] |
        map(
          "## " + .author_login + " — " + .state +
          (if .submitted_at then " (" + (.submitted_at | split("T") | .[0]) + ")" else "" end) +
          (if .body and (.body | length > 0) then "\n\n" + .body else "" end) +
          (if .comments and (.comments | length > 0) then "\n\n" +
            ([.comments[] |
              "### `" + .path + ":" + (.line | tostring) + "`" +
              (if .is_resolved then " ✅" else "" end) +
              (if .is_outdated then " ~~outdated~~" else "" end) +
              (if .code_context then
                "\n\n```" + (.path | split(".") | last) + "\n" + (.code_context | rtrimstr("\n")) + "\n```"
              else "" end) +
              "\n\n**" + .author_login + ":** " + .body +
              (if .thread_comments and (.thread_comments | length > 0) then
                "\n" + ([.thread_comments[] |
                  "\n> **" + .author_login + ":** " + .body
                ] | join(""))
              else "" end)
            ] | join("\n\n---\n\n"))
          else "" end)
        ) | join("\n\n===\n\n")
      ' $tmpfile
    else if set -q _flag_pretty; and test "$output_type" = threads
      jq -r '
        map(
          "### `" + .path + ":" + (.line | tostring) + "` — " + .threadId +
          (if .isResolved then " ✅" else "" end) +
          (if .isOutdated then " ~~outdated~~" else "" end) +
          (if .code_context then
            "\n\n```" + (.path | split(".") | last) + "\n" + (.code_context | rtrimstr("\n")) + "\n```"
          else "" end) +
          "\n\nUpdated: " + (.updatedAt | split("T") | .[0])
        ) | join("\n\n---\n\n")
      ' $tmpfile
    else if set -q _flag_raw
      cat $tmpfile
    else
      jq . $tmpfile
    end

    rm -f $tmpfile
  '';
}
