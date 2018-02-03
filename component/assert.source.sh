#!/bin/bash
# NOTES
#	> Variables declared within the functions below are prefixed by 'asrt'.
#	This prefix acts as a namespace to avoid accidentially colliding with
#	variables that are passed to the assert functions.
#	> Function & global variable names prefixed by "assert__"... are considered
#	private to this include	file - they should only be used/called by functions
#	within it.

# use this public constant variable to prefix the lines in the expected test
# output to perform a regex comparison when comparing it to the generated output
# instead of simple equality.
assert_REGEX_COMPARE='<RegEx>'
assert_INPUT_CMD_DELIMITER='---'
# public assert_output_* functions expect a command as the first argument
# followed by zero or more of its arguments.  Note - first argument can be 
# compound - containing both a command and a single varable. ex: "echo hello"
# but this form won't work for functions of two or more parameters due to 
# bash's line spliting algorithm. 
assert_output_true(){
	assert__output_bool ' ' "$@" 
}
assert_output_false(){ 
	assert__output_bool '!' "$@"
}
assert__output_bool(){
	# execute expected function before defining many other
	# local variables to ensure generation function binds,
	# if it needs to, to variables declared outside the
	# scope of this function. 
	local -i asrtPasInputPos
	local -i asrtPasOutLen
	assert__cmd_input_find 'asrtPasInputPos' 'asrtPasOutLen' "${@:2}"
	local asrtFDesc
	exec {asrtFDesc}< <( $2 "${@:3:$asrtPasOutLen-1}" ) 
	local -r asrtNegate="$1"
	local asrtIsCompareFail='true'
	local asrtGeneratedCnt
	local asrtExpectedCnt
	while true; do
		# read from STDIN first
		local -i asrtPasGenInCnt
		local -i asrtPasExptOutCnt
		if [ "$asrtPasInputPos" -gt 0 ]; then
			# read from provided input generation function
			if ! assert__output_compare "$asrtNegate" "$asrtFDesc" 'asrtPasGenInCnt' 'asrtPasExptOutCnt' < <( ${@:$asrtPasInputPos+1:1} "${@:$asrtPasInputPos+2}" ); then
				break
			fi
		elif ! assert__output_compare "$asrtNegate" "$asrtFDesc" 'asrtPasGenInCnt' 'asrtPasExptOutCnt'; then
			break
		fi
		(( asrtGeneratedCnt = asrtPasGenInCnt ))
		(( asrtExpectedCnt  = asrtPasExptOutCnt ))
		while read -r -u $asrtFDesc; do
			((asrtExpectedCnt++))
		done
		asrtIsCompareFail='false'
		break
	done
	# always close file handle to expected output
	eval exec $asrtFDesc\>\&\- 
	if $asrtIsCompareFail; then
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
	if [ $asrtGeneratedCnt -ne $asrtExpectedCnt ]; then 
		assert__msg_failed "generatedCnt='$asrtGeneratedCnt'" "expected_Cnt='$asrtExpectedCnt'"	
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
}

assert__cmd_input_find(){
	local -r asrtRtnInputPos="$1"
	local -r asrtRtnOutLen="$2"
	shift 2
	local -i asrtOutLen=$#
	local -i asrtInputPos=0
	local -i asrtDelmPos
	for (( asrtDelmPos=1; $# > 1; asrtDelmPos++ )){
		if [ "$1" == "$assert_INPUT_CMD_DELIMITER" ]; then
			(( asrtInputPos=asrtDelmPos + 1 ))
			break
		 fi
	shift
	}
	if [ $asrtInputPos -gt 0 ]; then
		(( asrtOutLen = asrtInputPos - 2 ))
	fi
	eval $asrtRtnInputPos=\$asrtInputPos
	eval $asrtRtnOutLen=\$asrtOutLen
}

assert__output_compare(){
	local -r asrtNegate="$1"
	local -r asrtFDesc="$2"
	local -r asrtRtnGenInCnt="$3"
	local -r asrtRtnExptOutCnt="$4"

	local asrtCompOper
	local asrtEval
	local asrtGenerated
	local asrtGeneratedCnt=0
	local asrtExpected
	local asrtExpectedCnt=0
	while read -r asrtGenerated; do
		((asrtGeneratedCnt++))
		if read -r -u $asrtFDesc asrtExpected; then
			((asrtExpectedCnt++))
		fi
		asrtCompOper='true'
		if [[ "${asrtExpected:0:${#assert_REGEX_COMPARE}}" == "$assert_REGEX_COMPARE" ]]; then
			asrtCompOper='false'
			asrtExpected="${asrtExpected:${#assert_REGEX_COMPARE}}"
		fi
		asrtEval='true'
		# need two different comparators statements: 
		#	1. Regex expressions, that appear in RHS of regex comparison,
	   	#	must not be encapsulated in quotes because if they are quoted,
		#	they are evaluated as just an ordnary string of characters.    
		#	2. The equality operator requires both its operands encapsulated
	   	#	by double quotes to prevent certain characters like '[' and ']'
		#	from interferring with its evaluation.
		#	3. Finally, the LHS operand of a regex operator must also be
		#	quote encapulated for the very same reason the equality operator's
	   	#	LHS is encapsulted by quotes.
		if $asrtCompOper; then 
			eval $asrtNegate \[ \"\$asrtGenerated\" == \"\$asrtExpected\" \] \|\| asrtEval\=\'false\'
		else
			eval $asrtNegate \[\[ \"\$asrtGenerated\" =~ \$asrtExpected \]\] \|\| asrtEval\=\'false\'
		fi
		if ! $asrtEval; then
			assert__msg_failed "generated='$asrtGenerated'" "expected_='$asrtExpected'"	
			return 1
		fi
	done
	eval $asrtRtnGenInCnt=\"\$asrtGeneratedCnt\"
	eval $asrtRtnExptOutCnt=\"\$asrtExpectedCnt\"
}

assert_true(){
	assert__bool "$1" ' '
}
assert_false(){
	assert__bool "$1" '!'
}
assert__bool(){
	local -r asrtExpression="$1"
	local -r asrtNegate="$2"

	if eval $asrtNegate $asrtExpression; then
		return
	fi
	# messaging will fail if asrtExpression contains an unbalanced number of
   	# double quotes and the odd one isn't excaped - \" .  it may also succeed
	# but may be missing double quotes as the added enclosing ones below 
	# trigger string concatenation.  This is usually not an issue when the
	# asrtExpression variable encapsulates all strings in variables, as bash will properly
	# escape all quotes using either concatenation or '\'.
	# Ex:
	#	b='"'
	#	asrtExpression='$b'
	#	eval echo \"$asrtExpression\"
	# the expression won't trigger "unexpected EOF while looking for matching"
	# however, the following will trigger this exception:
	# Ex:
	#	b='"'
	#	eval echo \"$b\"
	# when the exception occurs, it's better to rewrite the test and encapsulate
	# the argument within a variable as other corrective mechanisms, like capturing
   	#	set -x or using a trap don't work very well and diminish performance.
	#
	eval assert__msg_failed \"expression\=\$asrtNegate \$asrtExpression\" \
		\'evalExpres\=\'\"\$asrtNegate\ \"\"$asrtExpression\"
	assert__raised_record
	assert__halt_check
}
assert__msg_failed(){
	echo "msg='${FUNCNAME[2]} failed'" >&2
	echo " +  $1" >&2
	echo " +  $2" >&2
	echo " +  lineNo=${BASH_LINENO[2]}" >&2
	# indirectly called from failing test :: use [3] to identify it.
	echo " +  source='${BASH_SOURCE[3]}' func='${FUNCNAME[3]}'" >&2
}
# default implementation supporting asserts that immediately halt or continue
assert__RAISED_SOMETIME_DURING_EXECUTION='false' 
assert_halt(){
	assert__halt_check(){
		exit 1
	}
}
assert_continue(){
	assert__halt_check(){
		return 1
	}
}
assert__raised_record(){
	assert__RAISED_SOMETIME_DURING_EXECUTION='true'
}
assert__halt_check(){
	return 1
}
assert_return_code_set(){
	! $assert__RAISED_SOMETIME_DURING_EXECUTION
}
