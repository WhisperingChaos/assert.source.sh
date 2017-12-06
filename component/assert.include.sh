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
# assert_output functions accept only a single argument.  That argument, in most
# cases should be the name of a bash function that writes to sysout.  
assert_output_true(){
	assert__output_bool "$1" ' '
}
assert_output_false(){ 
	assert__output_bool "$1" '!'
}
assert__output_bool(){
	local -r asrtExpectedFn="$1"
	# execute expected function before defining many other
	# local variables to ensure generation function binds,
	# if it needs to, to variables declared outside the
	# scope of this function. 
	local asrtFDesc
	exec {asrtFDesc}< <( $asrtExpectedFn ) 
	local -r asrtNegate="$2"

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
			eval exec $asrtFDesc\<\&\-
			assert__msg_failed "generated='$asrtGenerated'" "expected_='$asrtExpected'"	
			# note when participating in a pipe, recording and halting
			# don't affect the parent process
			assert__raised_record
			assert__halt_check
			return 1
		fi
	done
	while read -r -u $asrtFDesc; do
		((asrtExpectedCnt++))
	done
	eval exec $asrtFDesc\>\&\- 
	if [ $asrtGeneratedCnt -ne $asrtExpectedCnt ]; then 
		echo "msg='${FUNCNAME[1]} failed'" >&2
		assert__msg_failed "generatedCnt='$asrtGeneratedCnt'" "expected_Cnt='$asrtExpectedCnt'"	
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
	true
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
	echo "  $1" >&2
	echo "  $2" >&2
	echo "  lineNo=${BASH_LINENO[2]}" >&2
	# indirectly called from failing test :: use [3] to identify it.
	echo "  source='${BASH_SOURCE[3]}' func='${FUNCNAME[3]}'" >&2
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
assert_raised_check(){
	! $assert__RAISED_SOMETIME_DURING_EXECUTION
}
