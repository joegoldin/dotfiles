function ask
    clai query $argv
end

function rask
    clai -reply query $argv
end

function image
    clai -photo-dir ~/Downloads photo $argv
end

function askinput
    # Read input from standard input (piped in)
    read input_lines
    
    # Get the argument (question)
    set question (string join ' ' $argv)
    
    ask "Given: \"$input_lines\"\n$question"
end

function raskinput
    # Read input from standard input (piped in)
    read input_lines
    
    # Get the argument (question)
    set question (string join ' ' $argv)
    
    rask "Given: \"$input_lines\"\n$question"
end

function askraw
    clai -raw query $argv
end

function askcopy
    set output (askraw $argv)
    echo "$output"
    echo "$output" | pbcopy
end

function askrawcommand
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    clai -raw query "$prompt\nUser input: $argv"
end

function askcmd
    set output (askrawcommand $argv)
    echo "$output"
    echo "$output" | pbcopy
end

function askprevcmd
    # Get the argument (question)
    set question (string join ' ' $argv)
    
    ask "Previous Command: $history[1] \nGiven: $question"
end

function cask
    clai -chat-model claude-3-opus-20240229 query $argv
end

function crask
    clai -chat-model claude-3-opus-20240229 -reply query $argv
end

function cimage
    clai -chat-model claude-3-opus-20240229 -photo-dir ~/Downloads photo $argv
end

function caskinput
    # Read input from standard input (piped in)
    read input_lines
    
    # Get the argument (question)
    set question (string join ' ' $argv)
    
    cask "Given: \"$input_lines\"\n$question"
end

function craskinput
    # Read input from standard input (piped in)
    read input_lines
    
    # Get the argument (question)
    set question (string join ' ' $argv)
    
    crask "Given: \"$input_lines\"\n$question"
end

function caskraw
    clai -chat-model claude-3-opus-20240229 -raw query $argv
end

function caskcopy
    set output (caskraw $argv)
    echo "$output"
    echo "$output" | pbcopy
end

function caskrawcommand
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    clai -chat-model claude-3-opus-20240229 -raw query "$prompt\nUser input: $argv"
end

function caskcmd
    set output (caskrawcommand $argv)
    echo "$output"
    echo "$output" | pbcopy
end
