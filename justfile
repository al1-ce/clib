# #!/usr/bin/env -S just --justfile
# just reference: https://just.systems/man/en/
# monolith flavor: ~/.config/nvim/readme/build.md
#
# set positional-arguments

build: && _make

TEST_UNIT := "./bin/clib-test-library"

test: _make && (_check_leak TEST_UNIT) _warning_leak

test_full: _make && (_check_full TEST_UNIT) _warning_leak

test_complete:
    dub build     --compiler dmd
    dub test      --compiler dmd

    dub build     --compiler ldc2
    dub test      --compiler ldc2

    dub build     --compiler gdc
    dub test      --compiler gdc

unit: && _clean_vgcore _warning_leak
    @dub test --vquiet
    valgrind {{TEST_UNIT}}

_make:
    @dub build       --quiet
    @dub test        --vquiet

_clean_vgcore:
    @-rm vgcore.*

_check_leak PATH1: && _clean_vgcore
    valgrind {{PATH1}}

_check_full PATH1: && _clean_vgcore
    valgrind --leak-check=full --show-leak-kinds=all {{PATH1}}

_warning_leak:
    @echo "EXPECT LEAK OF <=72 BYTES UNTIL 23106 IS RESOLVED"

# Cheatsheet:
# Set a variable (variable case is arbitrary)
# SINGLE := "--single"
#
# Export variable
# export MYHOME := "/new/home"
#
# Join paths:
# PATHS := "path/to" / "file" + ".txt"
#
# Conditions
# foo := if "2" == "2" { "Good!" } else { "1984" }
#
# String literals
# escaped_string := "\"\\" # will eval to "\
# raw_string := '\"\\' # will eval to \"\\
# exec_string := `ls` # will be set to result of inner command
#
# Hide configuration from just --list, prepend _ or add [private]
# [private]
# _test: build_d
#
# Alias to a recipe (just noecho)
# alias noecho := _echo
#
# Silence commands or recipes by prepending @ (i.e hide "dub build"):
# @build_d_custom:
#     @dub build
#
# Continue even on fail  by adding "-"
# test:
#    -cat notexists.txt
#    echo "Still executes"
#
# Configuration using variable from above (and positional argument $1)
# buildFile FILENAME:
#     dub build {{SINGLE}} $1
#
# Set env ([linux] makes recipe be usable only in linux)
# [linux]
# @test_d:
#     #!/bin/bash
#
# A command's arguments can be passed to dependency (also default arguments)
# push target="debug": (build target)
#
# Use + (1 ore more) or * (0 or more) to make argument variadic. Must be last
# ntest +FILES="justfile1 justfile2":
#
# Run set configurations (recipe requirements)
# all: build_d build_d_custom _echo
#
# This example will run in order "a", "b", "c", "d"
# b: a && c d
#
# Each recipe line is executed by a new shell (use shebang to prevent)
# foo:
#     pwd    # This `pwd` will print the same directory…
#     cd bar
#     pwd    # …as this `pwd`!
