#!/usr/bin/env bash


declare -a sources
declare -a matches
IFS=""
params=($@)


is_expression_set=0
expression=""
nl=$'\n'

IFS=""
for param in "${params[@]}"
do

        [[ $param = "-n" ]] && line_numbers_status="true" &&  continue
        [[ $param = "-l" ]] && print_only_names_status="true" && continue
        [[ $param = "-i" ]] && case_insensitive_status="true" && continue
        [[ $param = "-v" ]] && invert_output_status="true" && continue
        [[ $param = "-x" ]] && match_whole_lines_status="true" && continue

        if (( is_expression_set == 0 ))
        then
                expression="$param"
                is_expression_set=1


        elif ! [[ -r $param ]]
        then
                echo 'Usage : grep <flags> "expression" files'
                exit 1;
        else
                sources+=( "$param"  )
        fi

done

